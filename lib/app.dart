import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/analytics.dart';
import 'services/app_settings.dart';
import 'services/practice_history.dart';
import 'services/subscription.dart';
import 'theme/app_theme.dart';
import 'widgets/analytics_scope.dart';
import 'widgets/app_settings_scope.dart';
import 'widgets/practice_history_scope.dart';
import 'widgets/subscription_scope.dart';

class RehearseApp extends StatefulWidget {
  const RehearseApp({
    super.key,
    this.history,
    this.settings,
    this.subscription,
    this.analytics,
  });

  /// Injected by tests; production builds read from device storage and the
  /// store.
  final PracticeHistory? history;
  final AppSettings? settings;
  final Subscription? subscription;
  final Analytics? analytics;

  @override
  State<RehearseApp> createState() => _RehearseAppState();
}

class _RehearseAppState extends State<RehearseApp> {
  late final PracticeHistory _history;
  late final AppSettings _settings;
  late final Subscription _subscription;
  late final Analytics _analytics;

  @override
  void initState() {
    super.initState();
    _history = widget.history ?? PracticeHistory();
    _settings = widget.settings ?? AppSettings();
    _subscription = widget.subscription ?? Subscription();
    _analytics = widget.analytics ?? Analytics();

    _history.load();
    _settings.load();
    _subscription.addListener(_reportSubscriptionState);
    _startAnalytics();
  }

  Future<void> _startAnalytics() async {
    await _analytics.start();
    _analytics.appOpened();
    // Loading the store can flip entitlement, so the super properties are
    // set from the listener as well as here.
    await _subscription.load();
    _reportSubscriptionState();
  }

  void _reportSubscriptionState() {
    _analytics.setSubscriptionState(
      isConfigured: _subscription.isConfigured,
      isPro: _subscription.isPro,
      freeSessionsRemaining: _subscription.freeSessionsRemaining,
    );
  }

  @override
  void dispose() {
    _subscription.removeListener(_reportSubscriptionState);
    if (widget.history == null) _history.dispose();
    if (widget.settings == null) _settings.dispose();
    if (widget.subscription == null) _subscription.dispose();
    if (widget.analytics == null) _analytics.dispose();
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
          child: AnalyticsScope(
            analytics: _analytics,
            child: MaterialApp(
              title: 'Rehearse',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
