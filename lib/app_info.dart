/// What the app calls itself when asked.
///
/// Duplicated from `pubspec.yaml` rather than read at runtime, because
/// reading it means a plugin and this is one string. `test/app_info_test.dart`
/// asserts the two agree, so it cannot quietly drift into a lie in a bug
/// report.
const appVersion = '1.0.0';
