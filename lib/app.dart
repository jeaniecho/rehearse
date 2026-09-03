import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/practice_history.dart';
import 'theme/app_theme.dart';
import 'widgets/app_settings_scope.dart';
import 'widgets/practice_history_scope.dart';

class RehearseApp extends StatefulWidget {
  const RehearseApp({super.key, this.history, this.settings});

  /// Injected by tests; production builds read from device storage.
  final PracticeHistory? history;
  final AppSettings? settings;

  @override
  State<RehearseApp> createState() => _RehearseAppState();
}

class _RehearseAppState extends State<RehearseApp> {
  late final PracticeHistory _history;
  late final AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _history = widget.history ?? PracticeHistory();
    _settings = widget.settings ?? AppSettings();
    _history.load();
    _settings.load();
  }

  @override
  void dispose() {
    if (widget.history == null) _history.dispose();
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PracticeHistoryScope(
      history: _history,
      child: AppSettingsScope(
        settings: _settings,
        child: MaterialApp(
          title: 'Rehearse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
