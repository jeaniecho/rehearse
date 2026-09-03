import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/practice_record.dart';
import '../models/practice_response.dart';
import '../models/scenario.dart';
import '../models/practice_summary.dart';
import '../models/subscription.dart';
import '../services/analytics.dart';
import '../services/practice_history.dart';
import '../services/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_scope.dart';
import '../widgets/app_shell.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/score_display.dart';
import '../widgets/subscription_scope.dart';
import 'paywall_screen.dart';

/// Everything the rehearsal history knows about you: how consistently you
/// practice, which skill is carrying you, and every session so far.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final history = PracticeHistoryScope.of(context);
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
    final history = PracticeHistoryScope.of(context);
    final records = history.records;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Your progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (records.isNotEmpty)
            IconButton(
              key: const Key('clear_history'),
              tooltip: 'Clear history',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: PageWidth(
        child: records.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyProgress(),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  MediaQuery.paddingOf(context).bottom + 30,
                ),
                children: [
                  const SizedBox(height: 8),
                  _StreakBanner(history: history),
                  const SizedBox(height: 16),
                  const _PlanCard(),
                  _SkillTrends(history: history),
                  const SizedBox(height: 16),
                  Text(
                    'Session history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${records.length} ${records.length == 1 ? 'rehearsal' : 'rehearsals'} on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final record in records) ...[
                    _SessionTile(record: record),
                    const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Your history never leaves this device.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Plan state plus Restore. Restore lives here rather than only on the
/// paywall because the stores require it to be reachable without an upgrade
/// prompt in the way.
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
      from: RestoreSource.progress,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
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
                        key: const Key('upgrade_from_progress'),
                        onPressed: () => PaywallScreen.show(
                          context,
                          trigger: PaywallTrigger.progressUpsell,
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
                      key: const Key('restore_from_progress'),
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
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.forest,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No rehearsals yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 300,
            child: Text(
              'Finish a practice and your score, skill balance, and streak '
              'start showing up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Pick a scenario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.history});

  final PracticeHistory history;

  @override
  Widget build(BuildContext context) {
    final streak = history.streakDays;
    final trend = history.scoreTrend();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak > 0
                          ? '$streak-day streak'
                          : '${history.records.length} rehearsed',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      streak > 0
                          ? history.practicedToday
                                ? 'You already practiced today. Nice.'
                                : 'Practice today to keep it alive.'
                          : 'Practice two days running to start a streak.',
                      style: const TextStyle(
                        color: Color(0xFFD9E5DD),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ScoreRing.onDark(
                score: history.averageScore,
                caption: 'AVG SCORE',
                diameter: 92,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BannerStat(
                value: '${history.sessionsThisWeek}',
                label: 'this week',
              ),
              const _BannerDivider(),
              _BannerStat(
                value: '${history.averageScore}',
                label: 'average score',
              ),
              const _BannerDivider(),
              _BannerStat(
                value: trend == null ? '—' : '${trend > 0 ? '+' : ''}$trend',
                label: trend == null ? 'trend soon' : 'recent trend',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB9CEC2), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BannerDivider extends StatelessWidget {
  const _BannerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _SkillTrends extends StatelessWidget {
  const _SkillTrends({required this.history});

  final PracticeHistory history;

  @override
  Widget build(BuildContext context) {
    final skills = history.averageSkills;
    final strongest = skills.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final weakest = skills.entries.reduce((a, b) => a.value <= b.value ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skills across every rehearsal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              strongest.value == weakest.value
                  ? 'Evenly balanced so far. Keep going to see a pattern.'
                  : '${strongest.key.label} is carrying you. '
                        '${weakest.key.label} is where the next point is.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            SkillBars(values: skills, spacing: 17),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.record});

  final PracticeRecord record;

  Scenario? get _scenario {
    for (final scenario in scenarios) {
      if (scenario.id == record.scenarioId) return scenario;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenario;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scenario?.tint ?? AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              scenario?.icon ?? Icons.forum_rounded,
              color: AppColors.ink,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario?.title ?? 'Retired scenario',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatRelativeDay(record.completedAt)} · ${record.mode.label}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Scored ${record.score} out of 100',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: record.score >= 68 ? AppColors.mint : AppColors.canvas,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${record.score}',
                style: TextStyle(
                  color: record.score >= 68
                      ? AppColors.forest
                      : AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today", "Yesterday", "3 days ago", then a plain date.
String formatRelativeDay(DateTime value, {DateTime? now}) {
  DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

  final days = dayOf(now ?? DateTime.now()).difference(dayOf(value)).inDays;
  return switch (days) {
    <= 0 => 'Today',
    1 => 'Yesterday',
    < 7 => '$days days ago',
    < 14 => 'Last week',
    _ => '${value.day}/${value.month}/${value.year}',
  };
}
