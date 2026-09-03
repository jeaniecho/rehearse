import 'package:flutter/widgets.dart';

import '../services/app_settings.dart';

/// Makes device preferences available to the widget tree and rebuilds
/// dependents when one changes.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    required AppSettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
    assert(settings != null, 'No AppSettingsScope found in context.');
    return settings!;
  }

  /// The nearest settings, or null when the tree has no scope — lets a
  /// screen be pumped standalone in a test.
  static AppSettings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }
}
