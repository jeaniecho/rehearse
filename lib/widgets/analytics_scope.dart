import 'package:flutter/widgets.dart';

import '../services/analytics.dart';

/// Makes the funnel available to the widget tree.
class AnalyticsScope extends InheritedNotifier<Analytics> {
  const AnalyticsScope({
    required Analytics analytics,
    required super.child,
    super.key,
  }) : super(notifier: analytics);

  /// The nearest analytics, or null when the tree has no scope — a screen
  /// pumped standalone in a test simply records nothing.
  static Analytics? maybeOf(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<AnalyticsScope>()
        ?.widget;
    return scope is AnalyticsScope ? scope.notifier : null;
  }
}
