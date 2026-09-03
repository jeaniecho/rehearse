import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Where events go. Provider-agnostic on purpose: swapping PostHog for
/// Amplitude, Mixpanel, or Segment is one class, not a rewrite of every
/// call site.
abstract interface class AnalyticsSink {
  /// Returns false when no key is configured. Analytics then goes nowhere
  /// and the app is otherwise unaffected.
  Future<bool> configure();

  Future<void> track(String event, Map<String, Object> properties);

  /// Properties attached to every subsequent event.
  Future<void> setSuperProperties(Map<String, Object> properties);
}

abstract final class AnalyticsKeys {
  static const posthogKey = String.fromEnvironment('REHEARSE_POSTHOG_KEY');
  static const posthogHost = String.fromEnvironment(
    'REHEARSE_POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  static String? get key =>
      posthogKey.trim().isEmpty ? null : posthogKey.trim();
}

class PostHogAnalyticsSink implements AnalyticsSink {
  PostHogAnalyticsSink({String? apiKey, String? host})
    : _apiKey = apiKey ?? AnalyticsKeys.key,
      _host = host ?? AnalyticsKeys.posthogHost;

  final String? _apiKey;
  final String _host;
  bool _ready = false;

  @override
  Future<bool> configure() async {
    final apiKey = _apiKey;
    if (apiKey == null) return false;

    try {
      final config = PostHogConfig(apiKey)
        ..host = _host
        // Screens and taps are named by the funnel below, not guessed from
        // the widget tree, and session replay would capture what people
        // type into a rehearsal.
        ..captureApplicationLifecycleEvents = false
        ..sessionReplay = false
        ..debug = kDebugMode;

      await Posthog().setup(config);
      _ready = true;
      return true;
    } on Object {
      // Analytics must never be the reason the app fails to start.
      return false;
    }
  }

  @override
  Future<void> track(String event, Map<String, Object> properties) async {
    if (!_ready) return;
    try {
      await Posthog().capture(eventName: event, properties: properties);
    } on Object {
      // A dropped event is not worth surfacing to the person practicing.
    }
  }

  @override
  Future<void> setSuperProperties(Map<String, Object> properties) async {
    if (!_ready) return;
    try {
      for (final entry in properties.entries) {
        await Posthog().register(entry.key, entry.value);
      }
    } on Object {
      // Same: never interrupt a rehearsal for telemetry.
    }
  }
}

/// The default when no key is configured. Every call is a no-op.
class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();

  @override
  Future<bool> configure() async => false;

  @override
  Future<void> track(String event, Map<String, Object> properties) async {}

  @override
  Future<void> setSuperProperties(Map<String, Object> properties) async {}
}

AnalyticsSink createAnalyticsSink() {
  return AnalyticsKeys.key == null
      ? const NoopAnalyticsSink()
      : PostHogAnalyticsSink();
}
