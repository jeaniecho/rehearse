import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/practice_history.dart';
import 'services/subscription.dart';
import 'theme/app_theme.dart';
import 'widgets/app_settings_scope.dart';
import 'widgets/practice_history_scope.dart';
import 'widgets/subscription_scope.dart';

class RehearseApp extends StatefulWidget {
  const RehearseApp({
    super.key,
    this.history,
    this.settings,
    this.subscription,
  });

  /// Injected by tests; production builds read from device storage and the
  /// store.
  final PracticeHistory? history;
  final AppSettings? settings;
  final Subscription? subscription;

  @override
  State<RehearseApp> createState() => _RehearseAppState();
}

class _RehearseAppState extends State<RehearseApp> {
  late final PracticeHistory _history;
  late final AppSettings _settings;
  late final Subscription _subscription;

  @override
  void initState() {
    super.initState();
    _history = widget.history ?? PracticeHistory();
    _settings = widget.settings ?? AppSettings();
    _subscription = widget.subscription ?? Subscription();
    _history.load();
    _settings.load();
    _subscription.load();
  }

  @override
  void dispose() {
    if (widget.history == null) _history.dispose();
    if (widget.settings == null) _settings.dispose();
    if (widget.subscription == null) _subscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PracticeHistoryScope(
      history: _history,
      child: AppSettingsScope(
        settings: _settings,
        child: SubscriptionScope(
          subscription: _subscription,
          child: MaterialApp(
            title: 'Rehearse',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
