import 'package:flutter/material.dart';

import '../models/practice_response.dart';
import '../models/scenario.dart';
import '../services/coach_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import 'results_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    required this.scenario,
    this.mode = PracticeMode.guided,
    this.coachService,
    super.key,
  });

  final Scenario scenario;
  final PracticeMode mode;
  final CoachService? coachService;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _scrollController = ScrollController();
  final _responseController = TextEditingController();
  final _responseFocus = FocusNode();
  final List<PracticeResponse> _responses = [];
  late final CoachService _coachService;
  int _turnIndex = 0;
  PracticeResponse? _selectedResponse;
  bool _isEvaluating = false;
  String? _inputError;

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
  }

  void _select(ResponseChoice choice) {
    if (_selectedResponse != null) return;
    setState(() => _selectedResponse = PracticeResponse.fromChoice(choice));
    _scrollToBottom();
  }

  Future<void> _submitFreeform() async {
    final text = _responseController.text.trim();
    if (text.length < 3) {
      setState(() => _inputError = 'Write at least a few words to continue.');
      return;
    }

    _responseFocus.unfocus();
    setState(() {
      _isEvaluating = true;
      _inputError = null;
    });

    try {
      final evaluation = await _coachService.evaluate(
        scenario: widget.scenario,
        turn: _turn,
        turnIndex: _turnIndex,
        history: List.unmodifiable(_responses),
        responseText: text,
      );
      if (!mounted) return;
      setState(() {
        _selectedResponse = evaluation;
        _isEvaluating = false;
      });
      _scrollToBottom();
    } on Object {
      if (!mounted) return;
      setState(() {
        _isEvaluating = false;
        _inputError = 'Your coach is unavailable. Please try again.';
      });
    }
  }

  void _continue() {
    final response = _selectedResponse;
    if (response == null) return;

    _responses.add(response);
    if (_turnIndex == widget.scenario.turns.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultsScreen(
            scenario: widget.scenario,
            responses: List.unmodifiable(_responses),
            mode: widget.mode,
          ),
        ),
      );
      return;
    }

    setState(() {
      _turnIndex += 1;
      _selectedResponse = null;
      _responseController.clear();
      _inputError = null;
    });
    _scrollToBottom();
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
        leading: IconButton(
          tooltip: 'Leave practice',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.scenario.personName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.mode == PracticeMode.freestyle
                  ? 'FREE-FORM SIMULATION'
                  : 'GUIDED SIMULATION',
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
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
            minHeight: 4,
            color: AppColors.coral,
            backgroundColor: AppColors.border,
          ),
        ),
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: [
                  const _RoomNotice(),
                  const SizedBox(height: 22),
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
                    const SizedBox(height: 22),
                  ],
                  _PersonMessage(
                    key: ValueKey(_turnIndex),
                    scenario: widget.scenario,
                    text: _employeeLine,
                  ),
                  if (_selectedResponse != null) ...[
                    const SizedBox(height: 14),
                    _YourMessage(text: _selectedResponse!.text),
                    const SizedBox(height: 16),
                    _InlineCoach(response: _selectedResponse!),
                  ],
                ],
              ),
            ),
            _ResponsePanel(
              mode: widget.mode,
              turn: _turn,
              selectedResponse: _selectedResponse,
              isLastTurn: _turnIndex == widget.scenario.turns.length - 1,
              controller: _responseController,
              focusNode: _responseFocus,
              isEvaluating: _isEvaluating,
              inputError: _inputError,
              aiEnabled: _coachService.isAiEnabled,
              onSelect: _select,
              onSubmit: _submitFreeform,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.muted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Private practice · responses stay in this session',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _PersonMessage extends StatelessWidget {
  const _PersonMessage({required this.scenario, required this.text, super.key});

  final Scenario scenario;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
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
                child: Text(
                  scenario.personName,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
        const SizedBox(width: 34),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _ResponsePanel extends StatelessWidget {
  const _ResponsePanel({
    required this.mode,
    required this.turn,
    required this.selectedResponse,
    required this.isLastTurn,
    required this.controller,
    required this.focusNode,
    required this.isEvaluating,
    required this.inputError,
    required this.aiEnabled,
    required this.onSelect,
    required this.onSubmit,
    required this.onContinue,
  });

  final PracticeMode mode;
  final DialogueTurn turn;
  final PracticeResponse? selectedResponse;
  final bool isLastTurn;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEvaluating;
  final String? inputError;
  final bool aiEnabled;
  final ValueChanged<ResponseChoice> onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
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
                isEvaluating: isEvaluating,
                inputError: inputError,
                aiEnabled: aiEnabled,
                onSubmit: onSubmit,
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
    required this.isEvaluating,
    required this.inputError,
    required this.aiEnabled,
    required this.onSubmit,
    super.key,
  });

  final DialogueTurn turn;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEvaluating;
  final String? inputError;
  final bool aiEnabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                turn.prompt,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: aiEnabled ? AppColors.mint : AppColors.canvas,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    aiEnabled
                        ? Icons.auto_awesome_rounded
                        : Icons.offline_bolt_rounded,
                    color: aiEnabled ? AppColors.forest : AppColors.muted,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    aiEnabled ? 'AI COACH' : 'DEMO COACH',
                    style: TextStyle(
                      color: aiEnabled ? AppColors.forest : AppColors.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('freeform_response'),
          controller: controller,
          focusNode: focusNode,
          enabled: !isEvaluating,
          minLines: 2,
          maxLines: 3,
          maxLength: 600,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Type what you would say…',
            errorText: inputError,
            counterText: '',
            filled: true,
            fillColor: AppColors.canvas,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 9),
        FilledButton.icon(
          key: const Key('submit_response'),
          onPressed: isEvaluating ? null : onSubmit,
          icon: isEvaluating
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_upward_rounded),
          label: Text(isEvaluating ? 'Coach is listening…' : 'Send response'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
