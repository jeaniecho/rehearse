import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/scenario.dart';
import '../services/analytics.dart';
import '../services/practice_history.dart';
import '../services/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/subscription_scope.dart';
import 'brief_screen.dart';
import 'paywall_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// What to put in front of someone next: whatever they have rehearsed
  /// least, keeping the authored order as the tie-break so a fresh install
  /// still opens on the warm-up.
  static Scenario recommendedScenario(PracticeHistory history) {
    var best = scenarios.first;
    var fewest = history.recordsFor(best.id).length;

    for (final scenario in scenarios.skip(1)) {
      final reps = history.recordsFor(scenario.id).length;
      if (reps < fewest) {
        best = scenario;
        fewest = reps;
      }
    }
    return best;
  }

  void _openScenario(BuildContext context, Scenario scenario) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BriefScreen(scenario: scenario)),
    );
  }

  void _openProgress(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final history = PracticeHistoryScope.of(context);
    final subscription = SubscriptionScope.maybeOf(context);
    final recommended = recommendedScenario(history);
    final (headline, body) = _copy(history);

    return Scaffold(
      body: PageWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top,
            20,
            24,
          ),
          children: [
            Row(
              children: [
                // Flexible so the wordmark yields to the progress button
                // rather than pushing it off the edge at a large text scale.
                const Flexible(child: BrandMark()),
                const Spacer(),
                if (subscription?.isPro ?? false) ...[
                  const Text(
                    'PRO',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  key: const Key('open_progress'),
                  tooltip: 'Your progress',
                  onPressed: () => _openProgress(context),
                  icon: const Icon(Icons.bar_chart_rounded),
                  style: IconButton.styleFrom(foregroundColor: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (history.streakDays > 0) ...[
              _StreakChip(days: history.streakDays),
              const SizedBox(height: 14),
            ],
            Text(headline, style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 12),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            FilledButton(
              key: const Key('start_recommended'),
              onPressed: () => _openScenario(context, recommended),
              child: Text(
                history.isEmpty ? 'Start practicing' : 'Continue practicing',
              ),
            ),
            if (subscription != null && subscription.showsFreeAllowance) ...[
              const SizedBox(height: 14),
              _FreeAllowance(subscription: subscription),
            ],
            const SizedBox(height: 36),
            Text(
              'Conversations',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            for (final scenario in scenarios) ...[
              _ScenarioRow(
                scenario: scenario,
                recommended: scenario == recommended,
                reps: history.recordsFor(scenario.id).length,
                bestScore: history.bestScoreFor(scenario.id),
                onTap: () => _openScenario(context, scenario),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  /// What the screen leads with, which depends only on whether the habit is
  /// running. The streak itself is shown by the chip, not said twice here.
  (String, String) _copy(PracticeHistory history) {
    if (history.isEmpty) {
      return (
        'Say the hard thing.\nBetter.',
        'Rehearse the conversations most people put off, with someone on the '
            'other side who reacts to what you actually say.',
      );
    }
    if (history.practicedToday) {
      return (
        'One more rep?\nGo again.',
        'The second rehearsal is where the wording gets sharp. Nothing here '
            'is graded twice.',
      );
    }
    if (history.streakDays > 0) {
      return (
        'Keep the streak.\nOne conversation.',
        'A few minutes today holds the habit together.',
      );
    }
    return (
      'Ready for a\nharder one?',
      'You have rehearsed before. Today is a chance to make the message land '
          'faster.',
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '🔥 $days day streak',
          style: const TextStyle(
            color: AppColors.forest,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A quiet running total, so the paywall is never the moment someone first
/// learns the free practice was finite.
class _FreeAllowance extends StatelessWidget {
  const _FreeAllowance({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final remaining = subscription.freeSessionsRemaining;

    return Row(
      key: const Key('free_allowance'),
      children: [
        Expanded(
          child: Text(
            remaining == 0
                ? 'You’ve used your free rehearsals.'
                : remaining == 1
                ? '1 free rehearsal left.'
                : '$remaining free rehearsals left.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        TextButton(
          key: const Key('open_paywall'),
          onPressed: () =>
              PaywallScreen.show(context, trigger: PaywallTrigger.homeUpsell),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Go Pro'),
        ),
      ],
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    required this.scenario,
    required this.recommended,
    required this.reps,
    required this.bestScore,
    required this.onTap,
  });

  final Scenario scenario;
  final bool recommended;
  final int reps;
  final int? bestScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('scenario_${scenario.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: recommended ? AppColors.ink : AppColors.border,
              width: recommended ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scenario.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recommended) ...[
                      const Text(
                        'START HERE',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      scenario.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scenario.subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (bestScore case final best?) ...[
                      const SizedBox(height: 7),
                      Text(
                        reps == 1
                            ? '1 rep · best $best'
                            : '$reps reps · best $best',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
