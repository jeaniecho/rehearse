import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/practice_history.dart';
import 'theme/app_theme.dart';
import 'widgets/practice_history_scope.dart';

class RehearseApp extends StatefulWidget {
  const RehearseApp({super.key, this.history});

  /// Injected by tests; production builds read from device storage.
  final PracticeHistory? history;

  @override
  State<RehearseApp> createState() => _RehearseAppState();
}

class _RehearseAppState extends State<RehearseApp> {
  late final PracticeHistory _history;

  @override
  void initState() {
    super.initState();
    _history = widget.history ?? PracticeHistory();
    _history.load();
  }

  @override
  void dispose() {
    if (widget.history == null) _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PracticeHistoryScope(
      history: _history,
      child: MaterialApp(
        title: 'Rehearse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
