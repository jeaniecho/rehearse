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

  final int initialTab;

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const HomeScreen(),
          ProgressScreen(onPickScenario: () => setState(() => _tab = 0)),
        ],
      ),
      bottomNavigationBar: _PaperNav(
        selected: _tab,
        onSelected: (index) => setState(() => _tab = index),
      ),
    );
  }
}

/// The navigation, as a piece of paper rather than a bar.
///
/// Everything else the app puts on this canvas is a card lifted slightly off
/// it — the scenario tiles, the plan card, the coaching notes — so the one
/// permanent control is made of the same thing: a white capsule with the
/// card's own border and contact shadow, sized to its contents and floated
/// off the bottom edge rather than ruled across it.
///
/// Two destinations is the reason it can be. A full-width bar divided in two
/// leaves each label marooned in half a screen; a capsule takes only the
/// width the words need.
class _PaperNav extends StatelessWidget {
  const _PaperNav({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // Sits in `bottomNavigationBar` rather than over the content. The
      // capsule is opaque, so anything scrolling under it would be hidden
      // rather than glimpsed — the float is a look, not a layer.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        // `Align` with a height factor, not `Center` — a bottom bar is given
        // the whole screen to size itself in, and `Center` takes all of it,
        // leaving the body nothing.
        child: Align(
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
              boxShadow: Paper.lift,
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
    final ink = isSelected ? AppColors.forest : AppColors.muted;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.mint : Colors.transparent,
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
                  // Flexible so a large text scale ellipsises inside the
                  // capsule rather than pushing it past the gutter.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
