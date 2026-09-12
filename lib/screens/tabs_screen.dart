import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/paper.dart';
import 'home_screen.dart';
import 'progress_screen.dart';

/// The two places you can be when you are not rehearsing.
///
/// An `IndexedStack` rather than a swapped child, so each tab keeps its
/// scroll position and its state when you come back to it.
///
/// You used to be a third destination. It is reached from the profile
/// button in each screen's header now — it is somewhere you visit rather
/// than somewhere you work, and giving it a third of the bar said otherwise.
///
/// Everything else in the app is still an imperative `Navigator.push` onto
/// the root navigator, which is what puts the rehearsal, the paywall and You
/// *over* this bar rather than inside it. There is no per-tab navigator, and
/// no router: a flow that covers the bar is the behaviour we want.
class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key, this.initialTab = 0});

  /// How much room the capsule takes above the home indicator.
  ///
  /// The bar floats over the content rather than sitting beside it, so the
  /// screens underneath cannot discover this from layout — it is added to
  /// their `MediaQuery` bottom padding instead, and a list that respects
  /// that inset can scroll its last row clear of the capsule. A test pins
  /// this number to what the capsule actually measures, because nothing
  /// else would notice the two drifting apart.
  /// 70, not the 72 it was: the rail lost the 1pt border on each side when
  /// it went charcoal, and the guard below caught the two drifting apart.
  static const navHeight = 70.0;

  final int initialTab;

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // The tabs are told the capsule is there, rather than having a
          // strip of the screen taken away from them. A bar that reserved
          // its own row left a full-width white band behind a control that
          // is meant to be floating on the page.
          MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(
                bottom: media.padding.bottom + TabsScreen.navHeight,
              ),
            ),
            child: IndexedStack(
              index: _tab,
              children: [
                const HomeScreen(),
                ProgressScreen(onPickScenario: () => setState(() => _tab = 0)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PaperNav(
              selected: _tab,
              onSelected: (index) => setState(() => _tab = index),
            ),
          ),
        ],
      ),
    );
  }
}

/// The navigation, as a piece of paper rather than a bar.
///
/// Sized to its contents and floated off the bottom edge rather than ruled
/// across it, over the content rather than beside it — the page runs to the
/// bottom of the screen and the capsule sits on top of it, which is the
/// whole point of the shape.
///
/// Two destinations is the reason it can be. A full-width bar divided in two
/// leaves each label marooned in half a screen; a capsule takes only the
/// width the words need.
///
/// **Charcoal, and this used to be white.** The goal written here was that
/// the one permanent control be "made of the same thing" as the cards it
/// floats over — a white capsule with the card's own border and shadow. On
/// a white page that worked, because the capsule was then the only white
/// object with depth and the shadow alone said it was floating. Once
/// [AppColors.ground] went warm, every card became a white sheet lifted off
/// it, and the capsule stopped being distinguishable from the content
/// underneath: on home it merged into the scenario tile behind it. The
/// stated goal had become the bug.
///
/// Charcoal is the fix that keeps the shape, and the shape is not the
/// problem — `filledButtonTheme` and `outlinedButtonTheme` are both
/// `StadiumBorder` while every surface in the app is a rounded rectangle,
/// so a stadium is what you press and a rectangle is what you read. A tab
/// is something you press. Nothing in the content layer is dark, so the
/// rail cannot be mistaken for a card, and charcoal already carries every
/// primary action in the app rather than introducing a colour.
///
/// Measured: [AppColors.onCharcoalMuted] on charcoal 6.67:1, charcoal on
/// the selected chip 12.27:1, the rail on the ground 10.96:1.
class _PaperNav extends StatelessWidget {
  const _PaperNav({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('tabs'),
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        // `Align` with a height factor, not `Center`, which would stretch
        // to whatever it is given.
        child: Align(
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(999),
              boxShadow: Paper.float,
            ),
            // The pills are `Flexible`, not the labels alone. A `Flexible`
            // inside a min-size row is handed the whole incoming width, so
            // labelling only the text let both pills ask for the full
            // capsule and overflow it — the flex has to sit at the level
            // that is actually competing for the space.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _NavPill(
                    icon: Icons.forum_rounded,
                    label: 'Practice',
                    isSelected: selected == 0,
                    onTap: () => onSelected(0),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: _NavPill(
                    icon: Icons.bar_chart_rounded,
                    label: 'Progress',
                    isSelected: selected == 1,
                    onTap: () => onSelected(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The selected tab is a white chip on the dark rail — a tab pulled
    // forward, rather than a tint laid on.
    final ink = isSelected ? AppColors.charcoal : AppColors.onCharcoalMuted;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: Key('tab_${label.toLowerCase()}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            // The capsule is smaller than a bar, so the tap target has to be
            // asserted rather than inherited from one.
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 19, color: ink),
                  const SizedBox(width: 8),
                  // Flexible so a large text scale wraps inside the capsule
                  // rather than pushing it past the gutter.
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
