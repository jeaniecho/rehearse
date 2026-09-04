import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'you_screen.dart';

/// The three places you can be when you are not rehearsing.
///
/// An `IndexedStack` rather than a swapped child, so each tab keeps its
/// scroll position and its state when you come back to it.
///
/// Everything else in the app is still an imperative `Navigator.push` onto
/// the root navigator, which is what puts the rehearsal and the paywall
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
          const YouScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('tabs'),
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.mint,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded, color: AppColors.forest),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(
              Icons.bar_chart_rounded,
              color: AppColors.forest,
            ),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.forest),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
