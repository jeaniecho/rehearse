import 'dart:async';

import 'package:flutter/material.dart';

import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/scenario.dart';
import '../models/session_outcome.dart';
import '../services/analytics.dart';
import '../services/app_settings.dart';
import '../services/coach_service.dart';
import '../services/speech_input_service.dart';
import '../services/speech_output_service.dart';
import '../theme/app_theme.dart';
import '../theme/paper.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/illustration.dart';
import 'results_screen.dart';

// Split only for length — the screen was 1,356 lines. These are `part`s
// rather than their own libraries so the widgets below stay private to this
// screen: they are its innards, not a set anything else may reach for. The
// cost is that a part carries no imports of its own; the library's are above.
part 'practice/transcript.dart';
part 'practice/composer.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    required this.scenario,
    this.mode = PracticeMode.guided,
    this.coachService,
    this.speechInputService,
    this.speechOutputService,
    this.difficulty = SimulationDifficulty.defensive,
    this.isRetry = false,
    super.key,
  });

  final Scenario scenario;
  final PracticeMode mode;

  /// How hard the other person pushes back. Reaches the simulation prompt;
  /// guided mode ignores it, because its replies are authored.
  final SimulationDifficulty difficulty;

  /// Set when this rehearsal was started from "Try again", so the retry
  /// funnel can be measured separately.
  final bool isRetry;
  final CoachService? coachService;
  final SpeechInputService? speechInputService;
  final SpeechOutputService? speechOutputService;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _scrollController = ScrollController();
  final _responseController = TextEditingController();
  final _responseFocus = FocusNode();
  final List<PracticeResponse> _responses = [];
  late final CoachService _coachService;
  late final SpeechInputService _speechInputService;
  late final SpeechOutputService _speechOutputService;
  AppSettings? _settings;
  Analytics? _analytics;
  final _startedAt = DateTime.now();
  bool _reachedReport = false;
  bool _startReported = false;
  int _turnIndex = 0;
  PracticeResponse? _selectedResponse;

  /// Rendered the moment it is sent, before the reply exists (PRD §28).
  String? _pendingManagerLine;
  bool _isThinking = false;
  bool _isSummarizing = false;
  String? _summaryError;
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _voiceAvailable = false;
  bool _isSpeaking = false;
  String? _spokenLine;
  String? _inputError;
  String? _speechError;
  String _speechPrefix = '';

  /// Voice is on unless the manager has muted it. Without a settings scope
  /// (a screen pumped on its own) it simply stays on.
  bool get _voiceEnabled => _settings?.spokenRepliesEnabled ?? true;

  DialogueTurn get _turn => widget.scenario.turns[_turnIndex];

  String get _employeeLine {
    if (_turnIndex > 0) {
      final reply = _responses.last.employeeReply;
      if (reply != null && reply.isNotEmpty) return reply;
    }
    return _turn.employeeLine;
  }

  @override
  void initState() {
    super.initState();
    _coachService = widget.coachService ?? createCoachService();
    _speechInputService =
        widget.speechInputService ?? DeviceSpeechInputService();
    _speechOutputService =
        widget.speechOutputService ?? DeviceSpeechOutputService();
    unawaited(_prepareVoice());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = AppSettingsScope.maybeOf(context);
    _analytics = AnalyticsScope.maybeOf(context);

    if (_startReported) return;
    _startReported = true;
    _analytics?.simulationStarted(
      widget.scenario,
      mode: widget.mode,
      difficulty: widget.difficulty,
      isRetry: widget.isRetry,
    );
  }

  int get _elapsedSeconds => DateTime.now().difference(_startedAt).inSeconds;

  /// A device with no usable voice just stays quiet — spoken replies are an
  /// enhancement, never a prerequisite for practicing.
  Future<void> _prepareVoice() async {
    final available = await _speechOutputService.initialize(
      onSpeakingChanged: _handleSpeakingChanged,
    );
    if (!mounted) return;
    setState(() => _voiceAvailable = available);
    _speakEmployeeLine();
  }

  /// Reads the line the other person just delivered, skipping one that has
  /// already been spoken so a rebuild cannot restart it.
  void _speakEmployeeLine({bool force = false}) {
    if (!_voiceAvailable || !_voiceEnabled) return;
    final line = _employeeLine;
    if (!force && line == _spokenLine) return;
    _spokenLine = line;
    unawaited(_speechOutputService.speak(line));
  }

  void _handleSpeakingChanged(bool isSpeaking) {
    if (!mounted || _isSpeaking == isSpeaking) return;
    setState(() => _isSpeaking = isSpeaking);
  }

  Future<void> _toggleVoice() async {
    final settings = _settings;
    if (settings == null) return;

    final enabled = !settings.spokenRepliesEnabled;
    await settings.setSpokenRepliesEnabled(enabled);
    if (!mounted) return;

    if (enabled) {
      _speakEmployeeLine(force: true);
    } else {
      await _speechOutputService.stop();
    }
  }

  Future<void> _replayEmployeeLine() async {
    if (_isSpeaking) {
      await _speechOutputService.stop();
      return;
    }
    _speakEmployeeLine(force: true);
  }

  void _select(ResponseChoice choice) {
    if (_selectedResponse != null) return;
    setState(
      () => _selectedResponse = PracticeResponse.fromChoice(choice, _turn),
    );
    _scrollToBottom();
  }

  /// Sends a free-form turn.
  ///
  /// The manager's own words appear immediately (PRD §28) and the other
  /// person answers when they answer. Nothing coaches in between — the
  /// consequence of a weak message is the reply it earns, not a note about
  /// it (PRD §7.3).
  Future<void> _submitFreeform() async {
    if (_isListening) await _stopListening();
    if (_isThinking) return;

    final text = _responseController.text.trim();
    if (text.length < 3) {
      setState(() => _inputError = 'Write at least a few words to continue.');
      return;
    }

    _responseFocus.unfocus();
    setState(() {
      _pendingManagerLine = text;
      _isThinking = true;
      _inputError = null;
      _responseController.clear();
    });
    _scrollToBottom();

    EmployeeReply reply;
    try {
      reply = await _coachService.respond(
        scenario: widget.scenario,
        difficulty: widget.difficulty,
        turnIndex: _turnIndex,
        history: List.unmodifiable(_responses),
        managerResponse: text,
      );
    } on Object {
      if (!mounted) return;
      // The transcript is never lost: put the words back so nothing has to
      // be retyped.
      setState(() {
        _isThinking = false;
        _pendingManagerLine = null;
        _responseController.text = text;
        _inputError = 'Couldn’t continue the conversation. Try again.';
      });
      return;
    }

    if (!mounted) return;
    final response = PracticeResponse.spoken(
      text: text,
      employeeReply: reply.text,
      source: reply.source,
    );
    setState(() {
      _pendingManagerLine = null;
      _isThinking = false;
    });
    _commit(
      response,
      // PRD §9: the conversation can be over before the turns are. Not on the
      // opening exchange though — one message is not a rehearsal, and a model
      // that declares victory immediately would take away the practice the
      // person came for.
      endEarly:
          reply.resolution != SimulationResolution.continuing &&
          _turnIndex >= _earliestResolvableTurn,
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    _responseFocus.unfocus();
    await _speechOutputService.stop();
    setState(() {
      _inputError = null;
      _speechError = null;
    });

    try {
      if (!_speechInitialized) {
        final available = await _speechInputService.initialize(
          onListeningChanged: _handleListeningChanged,
          onError: _handleSpeechError,
        );
        if (!mounted) return;
        _speechInitialized = true;
        if (!available) {
          setState(() {
            _speechError =
                'Speech input isn’t available here. You can still type your response.';
          });
          return;
        }
      }

      _speechPrefix = _responseController.text.trimRight();
      await _speechInputService.start(onResult: _handleSpeechResult);
    } on Object {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _speechError =
            'Speech input couldn’t start. You can try again or keep typing.';
      });
    }
  }

  Future<void> _stopListening() async {
    if (mounted) setState(() => _isListening = false);
    try {
      await _speechInputService.stop();
    } on Object {
      // The recognizer may already have ended after a platform timeout.
    }
  }

  void _handleListeningChanged(bool isListening) {
    if (!mounted || _isListening == isListening) return;
    setState(() => _isListening = isListening);
  }

  void _handleSpeechResult(String transcript, bool isFinal) {
    if (!mounted || transcript.trim().isEmpty) return;
    final separator = _speechPrefix.isEmpty ? '' : ' ';
    final text = '$_speechPrefix$separator${transcript.trim()}';
    setState(() {
      _responseController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _speechError = null;
      if (isFinal) _isListening = false;
    });
  }

  void _handleSpeechError(String message) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _speechError = message;
    });
  }

  void _continue() {
    final response = _selectedResponse;
    if (response == null) return;
    setState(() => _selectedResponse = null);
    unawaited(_commit(response));
  }

  /// The soonest a declared resolution is honoured. Index 1 is the second
  /// manager message.
  static const _earliestResolvableTurn = 1;

  /// Records a finished turn, then either moves on or closes the session.
  ///
  /// [endEarly] is PRD §9's first three end conditions — the other person
  /// accepted, or the conversation broke down. The fourth, running out of
  /// turns, is the `_turnIndex` check below.
  Future<void> _commit(
    PracticeResponse response, {
    bool endEarly = false,
  }) async {
    _responses.add(response);
    _analytics?.simulationMessageSent(
      widget.scenario,
      mode: widget.mode,
      turnIndex: _turnIndex,
      responseLength: response.text.length,
      source: response.source,
    );

    if (!endEarly && _turnIndex < widget.scenario.turns.length - 1) {
      setState(() {
        _turnIndex += 1;
        _responseController.clear();
        _inputError = null;
        _speechError = null;
      });
      _speakEmployeeLine();
      _scrollToBottom();
      return;
    }

    await _finish();
  }

  /// Scores the finished conversation.
  ///
  /// Guided mode already has a judgement for every turn, because the wording
  /// was authored. Free-form mode has none until now — this is the single
  /// call that reads the whole transcript.
  Future<void> _finish() async {
    setState(() {
      _isSummarizing = true;
      _summaryError = null;
    });
    _scrollToBottom();
    await _speechOutputService.stop();

    PracticeSummary summary;
    try {
      summary = widget.mode == PracticeMode.guided
          ? PracticeSummary.fromResponses(_responses)
          : await _coachService.evaluate(
              scenario: widget.scenario,
              history: List.unmodifiable(_responses),
            );
    } on Object {
      if (!mounted) return;
      // The transcript survives (PRD §26). Nothing has to be replayed.
      setState(() {
        _isSummarizing = false;
        _summaryError =
            'Couldn’t put your coaching report together. Your conversation is safe.';
      });
      return;
    }

    if (!mounted) return;
    _reachedReport = true;
    _analytics?.simulationCompleted(
      widget.scenario,
      mode: widget.mode,
      isRetry: widget.isRetry,
      turnCount: _responses.length,
      durationSeconds: _elapsedSeconds,
      summary: summary,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          scenario: widget.scenario,
          summary: summary,
          mode: widget.mode,
          isRetry: widget.isRetry,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    // Leaving before the report is the drop-off the roadmap asks to measure.
    if (!_reachedReport) {
      _analytics?.simulationAbandoned(
        widget.scenario,
        mode: widget.mode,
        turnReached: _turnIndex + 1,
        durationSeconds: _elapsedSeconds,
      );
    }
    unawaited(_speechInputService.cancel());
    unawaited(_speechOutputService.stop());
    _scrollController.dispose();
    _responseController.dispose();
    _responseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        titleSpacing: 0,
        leadingWidth: 52,
        leading: IconButton(
          tooltip: 'Leave practice',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.subtle,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.scenario.personInitials,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scenario.personName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    widget.scenario.personRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_voiceAvailable && _settings != null)
            IconButton(
              key: const Key('toggle_voice'),
              onPressed: _toggleVoice,
              tooltip: _voiceEnabled
                  ? 'Mute ${widget.scenario.personName}'
                  : 'Let ${widget.scenario.personName} speak',
              icon: Icon(
                _voiceEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: _voiceEnabled ? AppColors.forest : AppColors.muted,
                size: 21,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_turnIndex + 1} / ${widget.scenario.turns.length}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
            child: _TurnTicks(
              turnIndex: _turnIndex,
              turns: widget.scenario.turns.length,
            ),
          ),
        ),
      ),
      body: PageWidth(
        child: Column(
          children: [
            Expanded(
              // Bottom-aligned, so the conversation sits just above where
              // you answer and grows upward as it goes. Top-aligned, the
              // opening line was one paragraph stranded above two thirds of
              // an empty screen — which read as a page that had failed to
              // load rather than as a room gone quiet.
              child: Stack(
                children: [
                  // And a quiet room still has something in it. The
                  // scenario's own mark holds the space above the opening
                  // line, then clears as the conversation fills it — the
                  // alignment puts it in the upper third, which the
                  // transcript only reaches once there is enough said to
                  // have earned the room.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _responses.isEmpty ? 1 : 0,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOut,
                        child: Align(
                          alignment: const Alignment(0, -0.42),
                          child: Illustration.scenario(
                            widget.scenario.id,
                            size: Illustration.stageSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 34,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_responses.isEmpty) ...[
                              const _RoomNotice(),
                              const SizedBox(height: 20),
                            ],
                            for (
                              var index = 0;
                              index < _responses.length;
                              index++
                            ) ...[
                              _PersonMessage(
                                scenario: widget.scenario,
                                text: index == 0
                                    ? widget.scenario.turns.first.employeeLine
                                    : _responses[index - 1].employeeReply ??
                                          widget
                                              .scenario
                                              .turns[index]
                                              .employeeLine,
                              ),
                              const SizedBox(height: 14),
                              _YourMessage(text: _responses[index].text),
                              const SizedBox(height: 18),
                            ],
                            _PersonMessage(
                              key: ValueKey(_turnIndex),
                              scenario: widget.scenario,
                              text: _employeeLine,
                              isSpeaking: _isSpeaking,
                              onReplay: _voiceAvailable && _voiceEnabled
                                  ? _replayEmployeeLine
                                  : null,
                            ),
                            // Guided mode previews the chosen line with its authored
                            // note; free-form mode never coaches mid-conversation.
                            if (_selectedResponse case final selected?) ...[
                              const SizedBox(height: 14),
                              _YourMessage(text: selected.text),
                              if (selected.feedback.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _InlineCoach(response: selected),
                              ],
                            ],
                            if (_pendingManagerLine case final pending?) ...[
                              const SizedBox(height: 14),
                              _YourMessage(text: pending),
                            ],
                            if (_isThinking) ...[
                              const SizedBox(height: 14),
                              _Typing(scenario: widget.scenario),
                            ],
                            if (_isSummarizing) ...[
                              const SizedBox(height: 22),
                              const _Summarizing(),
                            ],
                            if (_summaryError case final error?) ...[
                              const SizedBox(height: 22),
                              _SummaryFailed(message: error, onRetry: _finish),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isSummarizing && _summaryError == null)
              _ResponsePanel(
                mode: widget.mode,
                turn: _turn,
                selectedResponse: _selectedResponse,
                isLastTurn: _turnIndex == widget.scenario.turns.length - 1,
                controller: _responseController,
                focusNode: _responseFocus,
                isBusy: _isThinking || _isSummarizing,
                inputError: _inputError,
                speechError: _speechError,
                isListening: _isListening,
                onSelect: _select,
                onSubmit: _submitFreeform,
                onToggleListening: _toggleListening,
                onContinue: _continue,
              ),
          ],
        ),
      ),
    );
  }
}
