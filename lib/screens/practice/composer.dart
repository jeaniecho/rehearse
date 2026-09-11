// What you answer with: the panel at the bottom of the rehearsal, in both
// modes. Imports live in the library — see practice_screen.
part of '../practice_screen.dart';

class _ResponsePanel extends StatelessWidget {
  const _ResponsePanel({
    required this.mode,
    required this.turn,
    required this.maxChoiceHeight,
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

  /// What the guided choices may grow to before they scroll — the screen's
  /// height, less what the conversation needs.
  final double maxChoiceHeight;
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
        boxShadow: Paper.ledge,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      // The height change is animated, and the panel is sized to whichever
      // control it is showing *now* rather than to the taller of the two.
      // `AnimatedSwitcher` stacks the outgoing child with the incoming one
      // and takes the size of the larger, so three guided choices becoming a
      // Continue button held the old height for the whole fade and then
      // dropped it in a single frame — which is what made the transcript
      // above jump.
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [
              // Pinned by its edges rather than filled: the outgoing child
              // keeps its own height while it fades — squeezed into the
              // incoming one's, three choice cards overflow — and the stack
              // clips whatever hangs past the panel as it shrinks.
              for (final child in previous)
                Positioned(top: 0, left: 0, right: 0, child: child),
              ?current,
            ],
          ),
          child: selectedResponse != null
              ? FilledButton.icon(
                  key: const Key('continue_practice'),
                  onPressed: onContinue,
                  icon: Icon(
                    isLastTurn
                        ? Icons.insights_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    isLastTurn ? 'See my coaching report' : 'Continue',
                  ),
                )
              : mode == PracticeMode.guided
              ? _GuidedChoices(
                  key: ValueKey(turn.prompt),
                  turn: turn,
                  onSelect: onSelect,
                  maxHeight: maxChoiceHeight,
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
      ),
    );
  }
}

class _GuidedChoices extends StatelessWidget {
  const _GuidedChoices({
    required this.turn,
    required this.onSelect,
    required this.maxHeight,
    super.key,
  });

  final DialogueTurn turn;
  final ValueChanged<ResponseChoice> onSelect;

  /// How much room the list may take before it starts scrolling.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(turn.prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 11),
        // Now that the answers are shown whole, three of them can run past
        // what a phone has left under the conversation — and at an
        // accessibility text size they certainly do. The list takes the
        // share of the screen the room hands it and scrolls inside that,
        // rather than pushing the person you are talking to off the top.
        //
        // The figure comes down from the screen's own layout rather than
        // from `MediaQuery.sizeOf`, which is zero in any harness that wraps
        // a screen in a bare `MediaQueryData` to set the text scale.
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < turn.choices.length; index++) ...[
                  _ChoiceButton(
                    choice: turn.choices[index],
                    index: index,
                    onTap: () => onSelect(turn.choices[index]),
                  ),
                  if (index != turn.choices.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
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
            fillColor: isListening ? AppColors.peach : AppColors.surface,
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
                    color: isListening ? AppColors.coral : AppColors.muted,
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
                      backgroundColor: AppColors.charcoal,
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
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
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
      color: AppColors.surface,
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                // Whole, not clamped to two lines with an ellipsis. These
                // are the words you are about to say; an answer you cannot
                // read to the end is not a choice, and the longer ones were
                // being cut exactly where they stop being polite and start
                // being specific.
                child: Text(
                  choice.text,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    height: 1.35,
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
