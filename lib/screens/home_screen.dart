import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../models/scenario.dart';
import '../services/analytics.dart';
import '../services/practice_history.dart';
import '../services/subscription.dart';
import '../theme/app_theme.dart';
import '../theme/paper.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/eyebrow.dart';
import '../widgets/illustration.dart';
import '../widgets/practice_history_scope.dart';
import '../widgets/score_chip.dart';
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

/// The mark on a library tile.
///
/// Bigger than the 56 it was. The tiles carry a title and nothing else since
/// the footer moved into a chip, and at 56 — a third of the card's width,
/// with the mark's own transparent margin inside that — the drawing read as
/// an icon stranded in a large white card. The masters are cut at
/// `Illustration.stageSize`, so this costs nothing to draw.
const _tileMark = 72.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// What to put in front of someone next: whatever they have rehearsed
  /// least, the gentler of two that are equally unrehearsed, and the
  /// authored order after that.
  ///
  /// [subscription] narrows the field to what this person can actually
  /// start. The primary call to action on first run must not lead straight
  /// into a paywall — someone should meet the product before they meet the
  /// price — so a free account is recommended a free conversation. Locked
  /// ones are still reachable from the library below.
  ///
  /// Stakes are the tie-break because a fresh install has none of anything
  /// and would otherwise open on whichever conversation happens to be
  /// written first — which, since the free tier became the first of each
  /// tier, is a challenging one. The library is drawn as a ramp; the first
  /// thing recommended should be the foot of it.
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
      final gentler =
          reps == fewest && scenario.stakes.index < best.stakes.index;
      if (reps < fewest || gentler) {
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
            const AppHeader(),
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
                        Text(
                          headline,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        if (body case final body?) ...[
                          const SizedBox(height: 12),
                          Text(
                            body,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _NextUp(
                          scenario: recommended,
                          isFirst: history.isEmpty,
                          reps: history.recordsFor(recommended.id).length,
                          onTap: () => _openScenario(context, recommended),
                        ),
                        if (subscription?.showsLocks ?? false) ...[
                          const SizedBox(height: 16),
                          const _ProUpsell(),
                        ],
                      ],
                    ),
                  ),
                  // The rails label themselves. A "Conversations" heading
                  // over the first of them was a second level of labelling
                  // with nothing between the two, and the library is what
                  // the rest of this page is — it does not need announcing.
                  const SizedBox(height: 32),
                  // Grouped by what the situation is carrying, in order, so
                  // the library reads as a ramp rather than seven of the
                  // same thing. Skill would not group: all seven differ.
                  //
                  // The featured one is listed here as well. It was held out
                  // of the rails while the card above was the only way to
                  // reach it — the same scenario twice looked like a mistake
                  // — but the gap it left was worse: the warm-up rail was
                  // short by one for no reason a reader could see, and the
                  // library stopped being the whole library. The card is a
                  // recommendation, not a place.
                  for (final stakes in ScenarioStakes.values) ...[
                    _StakesGroup(
                      stakes: stakes,
                      history: history,
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
  /// running. The streak itself is worn in the header, not said twice here.
  ///
  /// Only the first run gets two lines and a paragraph under them: it is the
  /// one visit with nothing else to show, and the page has to say what the
  /// app is for. Every other state is a line — the block was a third of the
  /// screen before anything could be tapped, spent re-explaining a product
  /// the person has already used.
  (String, String?) _copy(PracticeHistory history) {
    if (history.isEmpty) {
      return (
        'Say the hard thing.\nBetter.',
        'Rehearse the conversations most people put off, with someone on the '
            'other side who reacts to what you actually say.',
      );
    }
    if (history.practicedToday) {
      return ('One more rep?', 'Nothing here is graded twice.');
    }
    if (history.streakDays > 0) {
      return ('Keep the streak.', null);
    }
    return ('Ready for\na harder one?', null);
  }
}

/// The offer, made where someone can still ignore it.
///
/// One line of mint, and it used to be a card: mark, eyebrow, headline and
/// two lines of body, at the size of the card for what to rehearse next and
/// in the only colour on the page. So the eye landed on the upsell before it
/// landed on the thing to do, and the library started below the fold. An
/// upsell should be the quietest permanent thing on a screen.
///
/// What it stopped saying — which conversations are free — is said by the
/// library itself: every locked tile carries a padlock, and the paywall this
/// opens states the tier in full.
class _ProUpsell extends StatelessWidget {
  const _ProUpsell();

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('pro_upsell'),
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        key: const Key('open_paywall'),
        onTap: () =>
            PaywallScreen.show(context, trigger: PaywallTrigger.homeUpsell),
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.mintEdge),
          ),
          child: Row(
            children: [
              // Big enough to read as the drawing it is: at thirty, a mark
              // cut for 120 went muddy on the tint.
              Illustration.proUnlock(size: 36),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Unlock all conversations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.forest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whatever to rehearse next, given its own card.
///
/// The old screen led with a bare "Continue practicing" button that never
/// said what it would open, above seven rows of equal weight. This says it.
///
/// Paper, not mint. A tint a shade off the page was not the reason this card
/// reads as the thing to do — the charcoal button on it is — and spending the
/// one coloured surface on the screen here left the offer below it arguing
/// for attention in white. So they are swapped: this is a sheet, like the
/// library tiles it recommends from, and the mint went to the Pro card.
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: Paper.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Illustration.scenario(scenario.id, size: Illustration.spotSize),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(reps == 0 ? 'START HERE' : 'GO AGAIN'),
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
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
    required this.subscription,
    required this.onOpen,
  });

  final ScenarioStakes stakes;
  final PracticeHistory history;
  final Subscription? subscription;
  final ValueChanged<Scenario> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = scenarios.where((s) => s.stakes == stakes).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Indented past the gutter to line up with the titles inside the
          // tiles rather than with the cards' outer edge — the label names
          // what the text under it says, so it sits on the same rail as
          // that text.
          padding: const EdgeInsets.only(left: 28, right: 20),
          child: Eyebrow(stakes.label.toUpperCase(), color: AppColors.muted),
        ),
        // Four, not twelve: the rail's own padding adds six above the cards
        // for their shadow, so a label that looked close to the tiles was
        // eighteen points off them.
        const SizedBox(height: 4),
        // A horizontal list has to be told its height, so it is derived from
        // the text scale rather than fixed: the illustration is a constant
        // but the two lines of title under it are not, and a rail that could
        // not grow would clip them at an accessibility size.
        //
        // The scaled term is the title alone now. It was the title and a
        // footer line; the state moved up beside the mark, and the rail gave
        // back the height that line was holding.
        SizedBox(
          height:
              _tileMark +
              40 +
              _railShadowRoom +
              MediaQuery.textScalerOf(context).scale(43),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: _railGutter,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) =>
                SizedBox(width: 168, child: _tile(items[index])),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _tile(Scenario scenario) => _ScenarioTile(
    scenario: scenario,
    bestScore: history.bestScoreFor(scenario.id),
    isLocked: subscription?.isLocked(scenario) ?? false,
    onTap: () => onOpen(scenario),
  );
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.bestScore,
    required this.isLocked,
    required this.onTap,
  });

  final Scenario scenario;

  /// The best of this scenario's rehearsals, and nothing about how many
  /// there were. A rep count on the tile answered a question nobody asks of
  /// a library — the count that means something is the streak, and the
  /// progress tab keeps the rest.
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
              // The state of the tile rides beside the mark rather than in a
              // row of its own under the title: it is one short thing, and a
              // line for it cost every tile the height of a line.
              //
              Row(
                // The chip hangs from the top of the row. Without this the
                // row centres its children, and an `Align` inside a centred
                // `Expanded` has nothing to align against — the box is only
                // as tall as the chip, so "top right" put it in the middle.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Illustration.scenario(scenario.id, size: _tileMark),
                  const SizedBox(width: 8),
                  // The chip takes the rest of the row and sits at the end
                  // of it, rather than being a flexible child beside a
                  // `Spacer`: two flexible children split the free space
                  // evenly, which gave the chip half of what it needed and
                  // ellipsed "Pro" down to its lock. Sized to its content
                  // here, and free to shrink at 1.6x, where the mark and the
                  // chip together outgrow the tile.
                  Expanded(
                    child: Align(
                      // The corner, not the middle of the row: it is a
                      // stamp on the card rather than a companion to the
                      // mark. `Align` inside the `Expanded` does it without
                      // moving the mark, which stays where the eye starts.
                      alignment: Alignment.topRight,
                      child: isLocked
                          ? const _LockedChip()
                          : bestScore == null
                          ? const SizedBox.shrink()
                          : ScoreChip(bestScore!, compact: true),
                    ),
                  ),
                ],
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// What a locked tile carries in the corner where a score would be.
///
/// A lock and no word. "Pro" beside it was the widest thing on the tile
/// after the title, it said what the lock already says, and the strip above
/// the library names the plan in full. The word is kept for screen readers,
/// which cannot see a padlock.
///
/// The artwork beside it is left at full strength on purpose: the mark is
/// what makes a scenario worth wanting, and dimming it would sell Pro by
/// making the library look broken.
class _LockedChip extends StatelessWidget {
  const _LockedChip();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pro',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: AppColors.subtle,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_rounded,
          size: 13,
          color: AppColors.charcoal,
        ),
      ),
    );
  }
}
