// What the conversation looks like: the other person's turns, your own, and
// the states between them. Imports live in the library — see practice_screen.
part of '../practice_screen.dart';

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
        color: AppColors.subtle,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: isSpeaking ? AppColors.forest : AppColors.border,
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
            color: AppColors.subtle,
            shape: BoxShape.circle,
          ),
          child: Text(
            scenario.personInitials,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
              color: AppColors.charcoal,
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      response.source.label.toUpperCase(),
                      style: TextStyle(
                        color: color.withValues(alpha: 0.72),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
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
            color: AppColors.subtle,
            shape: BoxShape.circle,
          ),
          child: Text(
            scenario.personInitials,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
