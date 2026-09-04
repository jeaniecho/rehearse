import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/app_info.dart';

void main() {
  test('the version shown in the app is the version being built', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);

    expect(declared, isNotNull, reason: 'no version line in pubspec.yaml');
    expect(
      appVersion,
      declared,
      reason: 'lib/app_info.dart and pubspec.yaml disagree',
    );
  });
}
