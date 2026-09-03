import 'package:flutter/widgets.dart';

import '../services/subscription.dart';

/// Makes entitlement and the free allowance available to the widget tree.
class SubscriptionScope extends InheritedNotifier<Subscription> {
  const SubscriptionScope({
    required Subscription subscription,
    required super.child,
    super.key,
  }) : super(notifier: subscription);

  static Subscription of(BuildContext context) {
    final subscription = context
        .dependOnInheritedWidgetOfExactType<SubscriptionScope>()
        ?.notifier;
    assert(subscription != null, 'No SubscriptionScope found in context.');
    return subscription!;
  }

  /// The nearest subscription, or null when the tree has no scope — lets a
  /// screen be pumped standalone in a test, and degrades to "never gate".
  static Subscription? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SubscriptionScope>()
        ?.notifier;
  }
}
