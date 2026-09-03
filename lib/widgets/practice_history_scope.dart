import 'package:flutter/widgets.dart';

import '../services/practice_history.dart';

/// Makes the device's practice history available to the widget tree and
/// rebuilds dependents whenever a rehearsal is recorded.
class PracticeHistoryScope extends InheritedNotifier<PracticeHistory> {
  const PracticeHistoryScope({
    required PracticeHistory history,
    required super.child,
    super.key,
  }) : super(notifier: history);

  /// The nearest history, subscribing the caller to its changes.
  static PracticeHistory of(BuildContext context) {
    final history = context
        .dependOnInheritedWidgetOfExactType<PracticeHistoryScope>()
        ?.notifier;
    assert(history != null, 'No PracticeHistoryScope found in context.');
    return history!;
  }

  /// The nearest history without subscribing, or null when the tree has no
  /// scope. For one-off writes that should not trigger a rebuild.
  static PracticeHistory? maybeOf(BuildContext context) {
    final scope =
        context
                .getElementForInheritedWidgetOfExactType<PracticeHistoryScope>()
                ?.widget
            as PracticeHistoryScope?;
    return scope?.notifier;
  }
}
