import 'package:flutter/material.dart';

import 'app.dart';
import 'services/crash_reporter.dart';

void main() {
  // Without a DSN this just runs the app, which is the normal case for a
  // local build and for every test.
  createCrashReporter().guard(() => runApp(const RehearseApp()));
}
