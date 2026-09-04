import 'package:flutter/material.dart';

import '../app_info.dart';
import '../models/subscription.dart';
import '../services/analytics.dart';
import '../services/practice_history.dart';
import '../services/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/eyebrow.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/subscription_scope.dart';
import 'paywall_screen.dart';

/// Your plan, your one preference, and your data.
///
/// These three lived on the progress screen, which meant that screen was
/// answering "how am I doing" and "what have you got of mine" at once.
/// Restore in particular has to be reachable without an upgrade prompt in
/// the way, and this is now the obvious place to look for it.
class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'You',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: PageWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.paddingOf(context).bottom + 30,
          ),
          children: const [
            SizedBox(height: 8),
            _PlanCard(),
            SizedBox(height: 22),
            _Preferences(),
            SizedBox(height: 22),
            _YourData(),
            SizedBox(height: 22),
            _About(),
          ],
        ),
      ),
    );
  }
}

/// Plan state plus Restore. Restore is here rather than only on the paywall
/// because the stores require it to be reachable without an upgrade prompt
/// in the way.
class _PlanCard extends StatefulWidget {
  const _PlanCard();

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  String? _notice;

  Future<void> _restore(Subscription subscription) async {
    final outcome = await subscription.restore();
    if (!mounted) return;

    AnalyticsScope.maybeOf(context)?.restoreCompleted(
      restored: outcome.unlocksPro,
      from: RestoreSource.settings,
    );
    setState(() => _notice = outcome.message);
  }

  @override
  Widget build(BuildContext context) {
    final subscription = SubscriptionScope.maybeOf(context);
    // An unconfigured build has no plan to talk about, so it says nothing.
    if (subscription == null || !subscription.isConfigured) {
      return const SizedBox.shrink();
    }

    final isPro = subscription.isPro;

    return Card(
      key: const Key('plan_card'),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPro ? AppColors.mint : AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPro
                        ? Icons.workspace_premium_rounded
                        : Icons.bolt_rounded,
                    color: isPro ? AppColors.forest : AppColors.muted,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'Rehearse Pro' : 'Free',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro
                            ? 'Unlimited rehearsals.'
                            : subscription.freeSessionsRemaining == 0
                            ? 'No free rehearsals left.'
                            : '${subscription.freeSessionsRemaining} of '
                                  '${Subscription.freeSessionLimit} free '
                                  'rehearsals left.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_notice case final notice?) ...[
              const SizedBox(height: 14),
              Text(
                notice,
                key: const Key('plan_notice'),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (!isPro) ...[
                  Expanded(
                    child: FilledButton(
                      key: const Key('upgrade_from_settings'),
                      onPressed: () => PaywallScreen.show(
                        context,
                        trigger: PaywallTrigger.settingsUpsell,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Go Pro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton(
                    key: const Key('restore_from_settings'),
                    onPressed: subscription.isBusy
                        ? null
                        : () => _restore(subscription),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Restore purchases'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The app has exactly one preference, and it is here rather than only in
/// the rehearsal so it can be found when you are not mid-conversation.
class _Preferences extends StatelessWidget {
  const _Preferences();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    if (settings == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('PREFERENCES'),
        const SizedBox(height: 10),
        Card(
          child: SwitchListTile(
            key: const Key('spoken_replies'),
            value: settings.spokenRepliesEnabled,
            onChanged: settings.setSpokenRepliesEnabled,
            contentPadding: const EdgeInsets.fromLTRB(17, 4, 11, 4),
            title: const Text(
              'Speak the replies',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'The other person answers out loud, using your device’s own '
              'voice. A device without one stays quiet either way.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pushback level',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  // Guided mode has authored replies, so it cannot honour
                  // this. Saying otherwise would be the cosmetic control
                  // PRD §7.2 warns against.
                  'Where a free-form rehearsal starts. You can still change '
                  'it for any single rehearsal on its briefing.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                DifficultyPicker(
                  keyPrefix: 'default_difficulty',
                  selected: settings.difficulty,
                  onChanged: settings.setDifficulty,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// What the app holds and how to be rid of it.
///
/// The copy here has to keep step with `docs/PRIVACY.md`, which describes
/// the same thing at length and is the published version.
class _YourData extends StatelessWidget {
  const _YourData();

  static Future<void> _confirmClear(
    BuildContext context,
    PracticeHistory history,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear your practice history?'),
        content: const Text(
          'Every session, score, and streak on this device is deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('confirm_clear_history'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              minimumSize: const Size(120, 44),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await history.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Every other section here degrades when its scope is absent, and this
    // one has to as well: the statement below is true either way, it is only
    // the button that needs a store to act on.
    final history = PracticeHistoryScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('YOUR DATA'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your scores, streak, and preferences stay on this device. '
                  'What you say in a free-form rehearsal is sent to the coach '
                  'to be answered and scored, and is never stored — not here, '
                  'and not there. Guided mode sends nothing at all.',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('clear_history'),
                    onPressed: history == null || history.isEmpty
                        ? null
                        : () => _confirmClear(context, history),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Clear practice history'),
                  ),
                ),
                const SizedBox(height: 10),
                // The counter is not the history: clearing is a privacy
                // action and must not hand back free rehearsals.
                const Text(
                  'Clearing does not restore free rehearsals.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// What this is, and a way back to the explanation of it.
class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('ABOUT'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              if (settings != null)
                ListTile(
                  key: const Key('replay_intro'),
                  contentPadding: const EdgeInsets.fromLTRB(17, 4, 11, 4),
                  onTap: settings.resetOnboarding,
                  title: const Text(
                    'Show the intro again',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'What a rehearsal is, and the four things it scores.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),
                child: Row(
                  children: [
                    const Text(
                      'Rehearse',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      appVersion,
                      key: const Key('app_version'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
