import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/scenario.dart';
import '../services/practice_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/practice_history_scope.dart';
import 'brief_screen.dart';
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
    final recommended = recommendedScenario(history);

    return Scaffold(
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ListView(
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const BrandMark(),
                const Spacer(),
                IconButton.filledTonal(
                  key: const Key('open_progress'),
                  tooltip: 'Your progress',
                  onPressed: () => _openProgress(context),
                  icon: const Icon(Icons.insights_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _HeroCard(
              history: history,
              onStart: () => _openScenario(context, recommended),
            ),
            const SizedBox(height: 14),
            _MomentumCard(
              history: history,
              onTap: () => _openProgress(context),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your practice',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Short scenarios. Real leadership muscles.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${scenarios.length} scenarios',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final scenario in scenarios) ...[
              _ScenarioCard(
                scenario: scenario,
                recommended: scenario == recommended,
                reps: history.recordsFor(scenario.id).length,
                bestScore: history.bestScoreFor(scenario.id),
                onTap: () => _openScenario(context, scenario),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Built for conversations that matter.',
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.history, required this.onStart});

  final PracticeHistory history;
  final VoidCallback onStart;

  (String, String, String) get _copy {
    final streak = history.streakDays;
    if (history.isEmpty) {
      return (
        'YOUR PRIVATE PRACTICE ROOM',
        'Say the hard thing.\nBetter.',
        'Practice high-stakes conversations, learn from each choice, and walk in ready.',
      );
    }
    if (history.practicedToday) {
      return (
        streak > 1 ? '$streak-DAY STREAK · DONE TODAY' : 'DONE FOR TODAY',
        'One more rep?\nGo again.',
        'The second rehearsal is where the wording gets sharp. Nothing here is graded twice.',
      );
    }
    if (streak > 0) {
      return (
        '$streak-DAY STREAK ON THE LINE',
        'Keep the streak.\nOne conversation.',
        'A few minutes today holds the habit together. Pick up where you left off.',
      );
    }
    return (
      'WELCOME BACK',
      'Ready for a\nharder one?',
      'You have rehearsed before. Today is a chance to make the message land faster.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (eyebrow, headline, body) = _copy;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -42,
            top: -52,
            child: _DecorativeCircle(size: 170, color: Color(0xFF2C684F)),
          ),
          const Positioned(
            right: 36,
            bottom: -62,
            child: _DecorativeCircle(size: 128, color: Color(0xFFE86D4A)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    eyebrow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.03,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFD9E5DD),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('start_recommended'),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    history.isEmpty
                        ? 'Start today’s practice'
                        : 'Start next practice',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    minimumSize: const Size(220, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Before the first rehearsal this sells the format; afterwards it reports
/// real numbers and becomes a doorway into the progress screen.
class _MomentumCard extends StatelessWidget {
  const _MomentumCard({required this.history, required this.onTap});

  final PracticeHistory history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trend = history.scoreTrend();

    // History loads asynchronously, so a returning manager sees the intro
    // card for a frame or two. Cross-fade rather than snap into the stats.
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Padding(
        key: ValueKey(history.isEmpty),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: history.isEmpty
            ? const Row(
                children: [
                  Expanded(
                    child: _ProofPoint(
                      icon: Icons.timer_outlined,
                      title: '4 min',
                      label: 'per practice',
                    ),
                  ),
                  _ProofDivider(),
                  Expanded(
                    child: _ProofPoint(
                      icon: Icons.forum_outlined,
                      title: '3 turns',
                      label: 'real dialogue',
                    ),
                  ),
                  _ProofDivider(),
                  Expanded(
                    child: _ProofPoint(
                      icon: Icons.lock_outline_rounded,
                      title: 'Private',
                      label: 'practice room',
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _ProofPoint(
                      icon: Icons.local_fire_department_rounded,
                      title: '${history.streakDays}',
                      label: 'day streak',
                    ),
                  ),
                  const _ProofDivider(),
                  Expanded(
                    child: _ProofPoint(
                      icon: Icons.event_available_outlined,
                      title: '${history.sessionsThisWeek}',
                      label: 'this week',
                    ),
                  ),
                  const _ProofDivider(),
                  Expanded(
                    child: _ProofPoint(
                      icon: Icons.insights_rounded,
                      title: '${history.averageScore}',
                      label: trend == null
                          ? 'average score'
                          : '${trend > 0 ? '+' : ''}$trend recently',
                    ),
                  ),
                ],
              ),
      ),
    );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('momentum_card'),
        onTap: history.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _ProofPoint extends StatelessWidget {
  const _ProofPoint({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title $label',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.coral),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ProofDivider extends StatelessWidget {
  const _ProofDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      child: VerticalDivider(color: AppColors.border, width: 1),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
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
    return Card(
      child: InkWell(
        key: Key('scenario_${scenario.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scenario.tint,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(scenario.icon, color: AppColors.ink, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recommended) ...[
                      Text(
                        reps == 0 ? 'RECOMMENDED' : 'UP NEXT',
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      scenario.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      scenario.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        MetaPill(
                          icon: Icons.bolt_rounded,
                          label: scenario.skill,
                        ),
                        MetaPill(
                          icon: Icons.timer_outlined,
                          label: '${scenario.durationMinutes} min',
                        ),
                        if (bestScore case final best?)
                          MetaPill(
                            icon: Icons.replay_rounded,
                            label: reps == 1
                                ? '1 rep · best $best'
                                : '$reps reps · best $best',
                            color: AppColors.forest,
                            backgroundColor: AppColors.mint,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
