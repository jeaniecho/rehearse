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

  /// The nearest history, or null when the tree has no scope — lets a screen
  /// be pumped standalone in a test.
  ///
  /// This subscribes, like every other scope whose value is rendered. It used
  /// not to, which read as a harmless optimisation for the write in
  /// `ResultsScreen` and was a bug everywhere else: history arrives after the
  /// first build — from the initial disk read, then from each finished
  /// rehearsal — so a caller that does not subscribe renders the state the
  /// app had at launch, forever. `AnalyticsScope` is the one that genuinely
  /// does not need to subscribe, because nothing reads it back.
  static PracticeHistory? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PracticeHistoryScope>()
        ?.notifier;
  }
}
