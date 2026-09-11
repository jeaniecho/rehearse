import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/scenario.dart';
import '../services/analytics.dart';
import '../services/practice_history.dart';
import '../services/subscription.dart';
import '../theme/app_theme.dart';
import '../theme/paper.dart';
import '../widgets/app_shell.dart';
import '../widgets/brand_mark.dart';
import '../widgets/eyebrow.dart';
import '../widgets/illustration.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/profile_button.dart';
import '../widgets/subscription_scope.dart';
import 'brief_screen.dart';
import 'paywall_screen.dart';

/// The page gutter. The scroll view cannot own it any more — the rails
/// have to reach past it — so everything that is not a rail asks for it.
const _gutter = EdgeInsets.symmetric(horizontal: 20);

/// The gutter, plus room for the contact shadow.
///
/// A horizontal list clips to its own bounds, so a card whose shadow falls
/// outside them has it sliced off along the bottom edge. `Paper.lift`
/// reaches four points down and blurs twelve, so sixteen below and a little
/// above keeps the whole of it inside the viewport.
const _railGutter = EdgeInsets.fromLTRB(20, 6, 20, 16);
const _railShadowRoom = 22.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// What to put in front of someone next: whatever they have rehearsed
  /// least, keeping the authored order as the tie-break so a fresh install
  /// still opens on the warm-up.
  ///
  /// [subscription] narrows the field to what this person can actually
  /// start. The primary call to action on first run must not lead straight
  /// into a paywall — someone should meet the product before they meet the
  /// price — so a free account is recommended a free conversation. Locked
  /// ones are still reachable from the library below.
  static Scenario recommendedScenario(
    PracticeHistory history, {
    Subscription? subscription,
  }) {
    final candidates = scenarios
        .where((s) => !(subscription?.isLocked(s) ?? false))
        .toList();
    // Belt and braces: `freeScenarioIds` is asserted non-empty by
    // `scenarios_test.dart`, so this only fires if that guard is removed.
    if (candidates.isEmpty) return scenarios.first;

    var best = candidates.first;
    var fewest = history.recordsFor(best.id).length;

    for (final scenario in candidates.skip(1)) {
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

  @override
  Widget build(BuildContext context) {
    final history = PracticeHistoryScope.of(context);
    final subscription = SubscriptionScope.maybeOf(context);
    final recommended = recommendedScenario(
      history,
      subscription: subscription,
    );
    final (headline, body) = _copy(history);

    return Scaffold(
      body: PageWidth(
        // The header sits outside the scrollable rather than being its
        // first row, so it stays put and the list cannot ride up under the
        // status bar. Onboarding is built the same way.
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top,
                20,
                // Space below the header, not above the list: the list's own
                // padding scrolls away, and without this the first line of
                // whatever is passing underneath is sliced against the logo.
                12,
              ),
              child: Row(
                children: [
                  // `Expanded`, not `Flexible` beside a `Spacer` — a spacer
                  // is a flex child too, so it was claiming half the row and
                  // truncating the app's own name to "rehear…" at a large
                  // text scale. The wordmark takes whatever the button
                  // leaves and aligns itself left.
                  const Expanded(child: BrandMark()),
                  // Pro is worn on the button itself, so the eyebrow that
                  // used to sit here would now say it twice.
                  const ProfileButton(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                // No horizontal padding: the rails below bleed to both
                // edges, because a card cut off by the screen is the only
                // thing that says there is more to the side. Everything
                // else asks for the gutter itself.
                // The bottom inset carries the floating bar as well as the
                // home indicator, so the last rail can be scrolled clear of
                // the capsule instead of living behind it.
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  Padding(
                    padding: _gutter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (history.streakDays > 0) ...[
                          _StreakChip(days: history.streakDays),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          headline,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 20),
                        _NextUp(
                          scenario: recommended,
                          isFirst: history.isEmpty,
                          reps: history.recordsFor(recommended.id).length,
                          onTap: () => _openScenario(context, recommended),
                        ),
                        if (subscription?.showsLocks ?? false) ...[
                          const SizedBox(height: 14),
                          const _FreeAllowance(),
                        ],
                        const SizedBox(height: 34),
                        Text(
                          'Conversations',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Grouped by what the situation is carrying, in order, so
                  // the library reads as a ramp rather than seven of the
                  // same thing. Skill would not group: all seven differ.
                  //
                  // The featured one is left out rather than repeated. On a
                  // phone the card and the grid are on screen together, and
                  // the same scenario twice reads as a mistake.
                  for (final stakes in ScenarioStakes.values) ...[
                    _StakesGroup(
                      stakes: stakes,
                      history: history,
                      exclude: recommended,
                      subscription: subscription,
                      onOpen: (scenario) => _openScenario(context, scenario),
                    ),
                  ],
                ],
              ),
            ),
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

/// A quiet statement of the shape of the free tier, so the paywall is never
/// the moment someone first learns that part of the library is closed.
class _FreeAllowance extends StatelessWidget {
  const _FreeAllowance();

  @override
  Widget build(BuildContext context) {
    final free = Subscription.freeScenarioIds.length;

    final label = Text(
      '$free conversations free, unlimited reps. The rest with Pro.',
      style: const TextStyle(color: AppColors.muted, fontSize: 13),
    );
    final action = TextButton(
      key: const Key('open_paywall'),
      onPressed: () =>
          PaywallScreen.show(context, trigger: PaywallTrigger.homeUpsell),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        // `styleFrom` replaces the button's text style rather than
        // merging into it, so a bare `TextStyle` here drops the family
        // and this one button renders in the platform font. The filled
        // and outlined button themes name it for the same reason.
        textStyle: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: const Text('Go Pro'),
    );

    // Beside the sentence at a normal size, under it once the type is big
    // enough that the two would fight for the width. Side by side at 1.6x,
    // the sentence wraps to three lines and the button floats against the
    // middle of them, which reads as a mistake rather than a pairing.
    final stacked = MediaQuery.textScalerOf(context).scale(13) > 17;

    return Container(
      key: const Key('free_allowance'),
      alignment: stacked ? Alignment.centerLeft : null,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 4), action],
            )
          : Row(
              children: [
                Expanded(child: label),
                action,
              ],
            ),
    );
  }
}

/// Whatever to rehearse next, given its own card.
///
/// The old screen led with a bare "Continue practicing" button that never
/// said what it would open, above seven rows of equal weight. This says it.
class _NextUp extends StatelessWidget {
  const _NextUp({
    required this.scenario,
    required this.isFirst,
    required this.reps,
    required this.onTap,
  });

  final Scenario scenario;
  final bool isFirst;
  final int reps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Illustration.scenario(scenario.id, size: Illustration.spotSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(
                      reps == 0 ? 'START HERE' : 'GO AGAIN',
                      color: AppColors.forest,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scenario.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${scenario.skill} · ${scenario.durationMinutes} min',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('start_recommended'),
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(isFirst ? 'Start practicing' : 'Continue practicing'),
          ),
        ],
      ),
    );
  }
}

/// One rung of the ramp: the scenarios carrying the same weight, two across.
class _StakesGroup extends StatelessWidget {
  const _StakesGroup({
    required this.stakes,
    required this.history,
    required this.exclude,
    required this.subscription,
    required this.onOpen,
  });

  final ScenarioStakes stakes;
  final PracticeHistory history;
  final Scenario exclude;
  final Subscription? subscription;
  final ValueChanged<Scenario> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = scenarios
        .where((s) => s.stakes == stakes && s != exclude)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _gutter,
          child: Eyebrow(stakes.label.toUpperCase(), color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        // A horizontal list has to be told its height, so it is derived from
        // the text scale rather than fixed: the illustration is a constant
        // but the two lines of title under it are not, and a rail that could
        // not grow would clip them at an accessibility size.
        SizedBox(
          height:
              Illustration.tileSize +
              58 +
              _railShadowRoom +
              MediaQuery.textScalerOf(context).scale(53),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: _railGutter,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) =>
                SizedBox(width: 168, child: _tile(items[index])),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _tile(Scenario scenario) => _ScenarioTile(
    scenario: scenario,
    reps: history.recordsFor(scenario.id).length,
    bestScore: history.bestScoreFor(scenario.id),
    isLocked: subscription?.isLocked(scenario) ?? false,
    onTap: () => onOpen(scenario),
  );
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.reps,
    required this.bestScore,
    required this.isLocked,
    required this.onTap,
  });

  final Scenario scenario;
  final int reps;
  final int? bestScore;

  /// Locked tiles still open. Reading a briefing is free (PRD §14), so the
  /// lock says what to expect rather than refusing the tap — nobody meets a
  /// paywall before they understand what it is standing in front of.
  final bool isLocked;
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: Paper.lift,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Illustration.scenario(scenario.id, size: Illustration.tileSize),
              const SizedBox(height: 10),
              Text(
                scenario.title,
                // The rail is a fixed height, so the title is capped rather
                // than allowed to push past it at a large text scale.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              if (isLocked)
                const _LockedFooter()
              else
                Text(
                  bestScore == null
                      ? '${scenario.durationMinutes} min'
                      : reps == 1
                      ? '1 rep · best $bestScore'
                      : '$reps reps · best $bestScore',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a locked tile says instead of its duration.
///
/// The artwork above it is left at full strength on purpose: the mark is
/// what makes a scenario worth wanting, and dimming it would sell Pro by
/// making the library look broken.
class _LockedFooter extends StatelessWidget {
  const _LockedFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, size: 13, color: AppColors.muted),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'Pro',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
