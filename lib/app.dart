import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/tabs_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/analytics.dart';
import 'services/app_settings.dart';
import 'services/practice_history.dart';
import 'services/subscription.dart';
import 'theme/app_theme.dart';
import 'widgets/app_settings_scope.dart';
import 'widgets/rehearse_scope.dart';

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

    // Home and onboarding have no AppBar to assert this for them.
    SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);

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
    return RehearseScope(
      history: _history,
      settings: _settings,
      subscription: _subscription,
      analytics: _analytics,
      child: MaterialApp(
        title: 'Rehearse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _Root(),
      ),
    );
  }
}

/// Chooses the first screen once preferences are known.
///
/// Waiting on [AppSettings.isLoaded] rather than assuming means a returning
/// manager never sees a flash of onboarding on a cold start.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: switch (settings) {
        AppSettings(isLoaded: false) => const _Launch(),
        AppSettings(onboardingCompleted: false) => const OnboardingScreen(),
        _ => const TabsScreen(),
      },
    );
  }
}

/// The one or two frames before preferences resolve.
///
/// Deliberately identical to the native splash — same canvas, same mark at
/// the same size — so the handoff from the platform launch screen to Flutter
/// is invisible rather than a flash of something else.
class _Launch extends StatelessWidget {
  const _Launch();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('launch'),
      backgroundColor: AppColors.ground,
      // Nothing on it. The native splash is the canvas colour alone, so the
      // frame that replaces it is too — there is no mark to hand over and
      // therefore nothing that can blink while one is decoded.
      body: SizedBox.expand(),
    );
  }
}
