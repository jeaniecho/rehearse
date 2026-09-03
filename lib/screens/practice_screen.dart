import 'dart:async';

import 'package:flutter/material.dart';

import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/scenario.dart';
import '../services/analytics.dart';
import '../services/app_settings.dart';
import '../services/coach_service.dart';
import '../services/speech_input_service.dart';
import '../services/speech_output_service.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_shell.dart';
import 'results_screen.dart';

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
    _commit(response);
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

  /// Records a finished turn, then either moves on or closes the session.
  Future<void> _commit(PracticeResponse response) async {
    _responses.add(response);
    _analytics?.simulationMessageSent(
      widget.scenario,
      mode: widget.mode,
      turnIndex: _turnIndex,
      responseLength: response.text.length,
      source: response.source,
    );

    if (_turnIndex < widget.scenario.turns.length - 1) {
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
    final progress = (_turnIndex + 1) / widget.scenario.turns.length;

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
                color: widget.scenario.tint,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.scenario.personInitials,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
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
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            color: AppColors.coralBright,
            backgroundColor: AppColors.border,
          ),
        ),
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        safeTop: false,
        safeBottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                children: [
                  if (_responses.isEmpty) ...[
                    const _RoomNotice(),
                    const SizedBox(height: 20),
                  ],
                  for (var index = 0; index < _responses.length; index++) ...[
                    _PersonMessage(
                      scenario: widget.scenario,
                      text: index == 0
                          ? widget.scenario.turns.first.employeeLine
                          : _responses[index - 1].employeeReply ??
                                widget.scenario.turns[index].employeeLine,
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

class _RoomNotice extends StatelessWidget {
  const _RoomNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.muted),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Private rehearsal · feedback appears after the conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonMessage extends StatelessWidget {
  const _PersonMessage({
    required this.scenario,
    required this.text,
    super.key,
    this.isSpeaking = false,
    this.onReplay,
  });

  final Scenario scenario;
  final String text;
  final bool isSpeaking;

  /// Tapping the bubble replays the line, or cuts it short mid-sentence.
  /// Null when the device has no voice or the manager has muted it.
  final Future<void> Function()? onReplay;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scenario.tint.withValues(alpha: 0.42),
          AppColors.surface,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: isSpeaking ? AppColors.forest : scenario.tint,
          width: isSpeaking ? 1.5 : 1,
        ),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scenario.tint,
            shape: BoxShape.circle,
          ),
          child: Text(
            scenario.personInitials,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 3, bottom: 5),
                child: Row(
                  children: [
                    Text(
                      scenario.personName,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isSpeaking) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        key: Key('speaking_indicator'),
                        size: 12,
                        color: AppColors.forest,
                      ),
                    ],
                  ],
                ),
              ),
              if (onReplay == null)
                bubble
              else
                Semantics(
                  button: true,
                  label: isSpeaking
                      ? 'Stop reading this line aloud'
                      : 'Replay this line aloud',
                  child: InkWell(
                    key: const Key('replay_line'),
                    onTap: onReplay,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    child: bubble,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

class _YourMessage extends StatelessWidget {
  const _YourMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 58),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineCoach extends StatelessWidget {
  const _InlineCoach({required this.response});

  final PracticeResponse response;

  bool get _isStrong => response.scoreDelta >= 8;

  @override
  Widget build(BuildContext context) {
    final color = _isStrong ? AppColors.forest : AppColors.coral;
    final background = _isStrong ? AppColors.mint : AppColors.peach;

    return Container(
      key: const Key('coach_feedback'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isStrong ? Icons.check_circle_rounded : Icons.tips_and_updates,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isStrong ? 'That builds trust' : 'Coach’s note',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      response.source.label.toUpperCase(),
                      style: TextStyle(
                        color: color.withValues(alpha: 0.72),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  response.feedback,
                  style: TextStyle(color: color, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The other person composing a reply. The only thing on screen between
/// sending and being answered, because nothing coaches in between.
class _Typing extends StatelessWidget {
  const _Typing({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('employee_typing'),
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scenario.tint,
            shape: BoxShape.circle,
          ),
          child: Text(
            scenario.personInitials,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var dot = 0; dot < 3; dot++) ...[
                if (dot != 0) const SizedBox(width: 5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// PRD §28 asks for an intentional transition while the report is built,
/// rather than a spinner over a dead screen.
class _Summarizing extends StatelessWidget {
  const _Summarizing();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('summarizing'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Reading the whole conversation back…',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The report failed, not the conversation. PRD §26: never make someone
/// replay a session they already had.
class _SummaryFailed extends StatelessWidget {
  const _SummaryFailed({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('summary_failed'),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('retry_summary'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry feedback'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsePanel extends StatelessWidget {
  const _ResponsePanel({
    required this.mode,
    required this.turn,
    required this.selectedResponse,
    required this.isLastTurn,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.inputError,
    required this.speechError,
    required this.isListening,
    required this.onSelect,
    required this.onSubmit,
    required this.onToggleListening,
    required this.onContinue,
  });

  final PracticeMode mode;
  final DialogueTurn turn;
  final PracticeResponse? selectedResponse;
  final bool isLastTurn;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final String? inputError;
  final String? speechError;
  final bool isListening;
  final ValueChanged<ResponseChoice> onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onToggleListening;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('response_panel'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: selectedResponse != null
            ? FilledButton.icon(
                key: const Key('continue_practice'),
                onPressed: onContinue,
                icon: Icon(
                  isLastTurn
                      ? Icons.insights_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(isLastTurn ? 'See my coaching report' : 'Continue'),
              )
            : mode == PracticeMode.guided
            ? _GuidedChoices(
                key: ValueKey(turn.prompt),
                turn: turn,
                onSelect: onSelect,
              )
            : _FreeformComposer(
                key: ValueKey(turn.prompt),
                turn: turn,
                controller: controller,
                focusNode: focusNode,
                isBusy: isBusy,
                inputError: inputError,
                speechError: speechError,
                isListening: isListening,
                onSubmit: onSubmit,
                onToggleListening: onToggleListening,
              ),
      ),
    );
  }
}

class _GuidedChoices extends StatelessWidget {
  const _GuidedChoices({required this.turn, required this.onSelect, super.key});

  final DialogueTurn turn;
  final ValueChanged<ResponseChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(turn.prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 11),
        for (var index = 0; index < turn.choices.length; index++) ...[
          _ChoiceButton(
            choice: turn.choices[index],
            index: index,
            onTap: () => onSelect(turn.choices[index]),
          ),
          if (index != turn.choices.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FreeformComposer extends StatelessWidget {
  const _FreeformComposer({
    required this.turn,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.inputError,
    required this.speechError,
    required this.isListening,
    required this.onSubmit,
    required this.onToggleListening,
    super.key,
  });

  final DialogueTurn turn;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final String? inputError;
  final String? speechError;
  final bool isListening;
  final VoidCallback onSubmit;
  final VoidCallback onToggleListening;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(turn.prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 9),
        TextField(
          key: const Key('freeform_response'),
          controller: controller,
          focusNode: focusNode,
          enabled: !isBusy,
          readOnly: isListening,
          minLines: 1,
          maxLines: 3,
          maxLength: 600,
          onSubmitted: (_) {
            if (!isBusy) onSubmit();
          },
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: isListening
                ? 'Listening…'
                : 'Say it out loud or type your response…',
            errorText: inputError,
            counterText: '',
            filled: true,
            fillColor: isListening ? AppColors.peach : AppColors.canvas,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
            suffixIconConstraints: const BoxConstraints(minWidth: 104),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('speech_input'),
                  onPressed: isBusy ? null : onToggleListening,
                  tooltip: isListening ? 'Stop listening' : 'Start speaking',
                  icon: Icon(
                    isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                    color: isListening ? AppColors.coral : AppColors.forest,
                    size: 23,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: IconButton.filled(
                    key: const Key('submit_response'),
                    onPressed: isBusy ? null : onSubmit,
                    tooltip: 'Send response',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      minimumSize: const Size(42, 42),
                    ),
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isListening ? AppColors.coral : AppColors.border,
                width: isListening ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: isListening || speechError != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isListening
                            ? Icons.graphic_eq_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: isListening ? AppColors.coral : AppColors.muted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          isListening
                              ? 'Listening… speak naturally, then tap stop.'
                              : speechError!,
                          key: const Key('speech_status'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isListening
                                    ? AppColors.coral
                                    : AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.index,
    required this.onTap,
  });

  final ResponseChoice choice;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        key: Key('choice_$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  choice.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
