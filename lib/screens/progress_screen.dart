import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/practice_record.dart';
import '../models/practice_response.dart';
import '../models/scenario.dart';
import '../models/practice_summary.dart';
import '../services/practice_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/eyebrow.dart';
import '../widgets/illustration.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/profile_button.dart';
import '../widgets/score_chip.dart';
import '../widgets/score_display.dart';

/// Everything the rehearsal history knows about you: how consistently you
/// practice, which skill is carrying you, and every session so far.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, this.onPickScenario});

  /// Switches to the practice tab. Null when this screen is pumped on its
  /// own, in which case the empty state falls back to popping.
  final VoidCallback? onPickScenario;

  @override
  Widget build(BuildContext context) {
    final history = PracticeHistoryScope.of(context);
    final records = history.records;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Your progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: const [ProfileAction()],
      ),
      body: PageWidth(
        child: records.isEmpty
            ? Padding(
                // The one layout here that centres rather than scrolls, so
                // it takes the bottom inset as padding — otherwise it
                // centres through the floating bar and sits low.
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.paddingOf(context).bottom,
                ),
                child: _EmptyProgress(onPickScenario: onPickScenario),
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
                  // Nothing to chart while every rehearsal so far was
                  // guided: the bars would be four empty tracks under a
                  // sentence about a pattern.
                  if (history.averageSkills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SkillTrends(history: history),
                  ],
                  const SizedBox(height: 32),
                  // An eyebrow, not a headline with a sentence under it. The
                  // library labels its rows this way and this is the same
                  // kind of thing — a list that needs naming, not a section
                  // that needs introducing. The count it used to carry is
                  // the list itself, and "newest first" is what a history
                  // is.
                  const Padding(
                    // Inset to the cards' own content, the way the library's
                    // row labels are — the label lines up with what it names
                    // rather than with the paper it is printed on.
                    padding: EdgeInsets.only(left: 14),
                    child: Eyebrow('SESSION HISTORY', color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  for (final record in records) ...[
                    _SessionTile(record: record),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress({this.onPickScenario});

  final VoidCallback? onPickScenario;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Illustration.emptyProgress(),
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
              onPressed:
                  onPickScenario ?? () => Navigator.of(context).maybePop(),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(20),
      ),
      // One card, one claim, then the numbers under a rule. The ring used to
      // sit here at 92pt and repeat the average score the row already gave,
      // in rust on green — the two loudest colours in the palette, touching.
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
          const SizedBox(height: 6),
          Text(
            streak > 0
                ? history.practicedToday
                      ? 'You already practiced today. Nice.'
                      : 'Practice today to keep it alive.'
                : 'Practice two days running to start a streak.',
            style: const TextStyle(
              color: AppColors.onForestMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (history.averageScore case final average?)
                _BannerStat(value: '$average', label: 'average score'),
              _BannerStat(
                value: '${history.sessionsThisWeek}',
                label: 'this week',
              ),
              // A third of the row said "—" over "trend soon" until there
              // were two weeks to compare, which is a placeholder wearing
              // the clothes of a number. The row is two stats until the
              // third one exists.
              if (trend case final trend?)
                _BannerStat(
                  value: '${trend > 0 ? '+' : ''}$trend',
                  label: 'recent trend',
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onForestMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillTrends extends StatelessWidget {
  const _SkillTrends({required this.history});

  final PracticeHistory history;

  @override
  Widget build(BuildContext context) {
    final skills = history.averageSkills;

    // The same call the bars make, so the sentence and the chart name the
    // same two skills — see `skillExtremes`.
    final (:strongest, :weakest) = skillExtremes(skills);
    final claims = [
      if (strongest != null) '${strongest.label} is carrying you.',
      if (weakest != null) '${weakest.label} is where the next point is.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skills across every rehearsal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              claims.isEmpty
                  ? 'Evenly balanced so far. Keep going to see a pattern.'
                  : claims.join(' '),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SkillBars(values: skills, spacing: 14),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // The scenario's own mark, as on the home grid. A Material glyph
          // on a pastel chip was the one place a scenario was labelled by
          // something other than the illustration drawn for it.
          SizedBox(
            width: 44,
            height: 44,
            child: scenario == null
                ? const Icon(
                    Icons.forum_rounded,
                    color: AppColors.muted,
                    size: 21,
                  )
                : Illustration.scenario(scenario.id, size: 44),
          ),
          const SizedBox(width: 13),
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
          // Guided rehearsals are not scored, so the row ends after its
          // meta line — which already says which mode it was.
          if (record.score case final score?) ScoreChip(score),
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
