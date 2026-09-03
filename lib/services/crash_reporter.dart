import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Where crashes go.
///
/// Behind an interface for the same reason as everything else here: the app
/// must run with no keys, and swapping Sentry for something else should be
/// one class rather than a change to `main`.
abstract interface class CrashReporter {
  /// Runs [app], reporting anything it throws. Returns without reporting
  /// anywhere when no DSN is configured.
  Future<void> guard(FutureOr<void> Function() app);

  /// Something the app recovered from but somebody should still know about.
  Future<void> reportHandled(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  });
}

abstract final class CrashKeys {
  static const dsn = String.fromEnvironment('REHEARSE_SENTRY_DSN');
  static const environment = String.fromEnvironment(
    'REHEARSE_ENVIRONMENT',
    defaultValue: 'development',
  );

  static String? get sentryDsn => dsn.trim().isEmpty ? null : dsn.trim();
}

class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter({String? dsn, String? environment})
    : _dsn = dsn ?? CrashKeys.sentryDsn,
      _environment = environment ?? CrashKeys.environment;

  final String? _dsn;
  final String _environment;
  bool _ready = false;

  @override
  Future<void> guard(FutureOr<void> Function() app) async {
    final dsn = _dsn;
    if (dsn == null) {
      await app();
      return;
    }

    try {
      await SentryFlutter.init((options) {
        options
          ..dsn = dsn
          ..environment = _environment
          // A crash report is for diagnosing a crash, not for learning
          // anything about the person who hit it.
          ..sendDefaultPii = false
          // Rehearsal text is the one thing that must never leave the
          // device except to the coach. A screenshot of the practice screen
          // would carry it, and so would a widget tree full of its Text
          // nodes, so neither is attached. `attachViewHierarchy` is off by
          // default and is left alone because the API is still experimental.
          ..attachScreenshot = false
          ..enableUserInteractionBreadcrumbs = false
          ..tracesSampleRate = 0
          ..debug = kDebugMode;
      }, appRunner: () => app());
      _ready = true;
    } on Object {
      // Telemetry must never be the reason the app does not start.
      _ready = false;
      await app();
    }
  }

  @override
  Future<void> reportHandled(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    if (!_ready) return;
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.level = SentryLevel.warning;
          if (context != null) scope.setTag('rehearse.context', context);
        },
      );
    } on Object {
      // Nothing to do if the reporter itself fails.
    }
  }
}

/// The default when no DSN is configured: runs the app and forgets errors.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> guard(FutureOr<void> Function() app) async => app();

  @override
  Future<void> reportHandled(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {}
}

CrashReporter createCrashReporter() {
  return CrashKeys.sentryDsn == null
      ? const NoopCrashReporter()
      : SentryCrashReporter();
}
