import 'package:flutter/widgets.dart';

import '../services/analytics.dart';
import '../services/app_settings.dart';
import '../services/practice_history.dart';
import '../services/subscription.dart';
import 'analytics_scope.dart';
import 'app_settings_scope.dart';
import 'practice_history_scope.dart';
import 'subscription_scope.dart';

/// The four service scopes, nested once.
///
/// `app.dart` and every harness that wants a realistic tree were writing the
/// same four-deep nest out by hand, which is four chances to leave one out
/// and get behaviour the app itself does not have.
///
/// Each service is optional, because a test that pumps one screen should
/// still be able to supply only what that screen reads. A scope left out is
/// simply absent, exactly as it was when the nest was written by hand —
/// `maybeOf` returns null and the feature degrades, `of` asserts.
class RehearseScope extends StatelessWidget {
  const RehearseScope({
    required this.child,
    this.history,
    this.settings,
    this.subscription,
    this.analytics,
    super.key,
  });

  final PracticeHistory? history;
  final AppSettings? settings;
  final Subscription? subscription;
  final Analytics? analytics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Built inside out, so the nesting order matches what it replaced.
    var tree = child;
    if (analytics case final analytics?) {
      tree = AnalyticsScope(analytics: analytics, child: tree);
    }
    if (subscription case final subscription?) {
      tree = SubscriptionScope(subscription: subscription, child: tree);
    }
    if (settings case final settings?) {
      tree = AppSettingsScope(settings: settings, child: tree);
    }
    if (history case final history?) {
      tree = PracticeHistoryScope(history: history, child: tree);
    }
    return tree;
  }
}
