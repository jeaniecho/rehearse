import 'package:flutter/foundation.dart';

import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/scenario.dart';
import 'analytics_sink.dart';

/// The product funnel from PRD §17, as typed calls rather than loose strings.
///
/// **No method here accepts free text.** Everything is an id, an enum, a
/// number, or a boolean, which is what makes PRD §16's rule — never send raw
/// conversation content to analytics — a property of the type system rather
/// than of everyone's discipline. If a new event needs a string, it needs a
/// new enum or an id, not a `String` parameter.
class Analytics extends ChangeNotifier {
  Analytics({AnalyticsSink? sink}) : _sink = sink ?? createAnalyticsSink();

  final AnalyticsSink _sink;
  bool _isEnabled = false;

  /// False when no key is configured. Everything still compiles and runs;
  /// the events simply go nowhere.
  bool get isEnabled => _isEnabled;

  Future<void> start() async {
    _isEnabled = await _sink.configure();
    if (_isEnabled) notifyListeners();
  }

  /// Entitlement travels with every later event, so any funnel can be split
  /// by free versus Pro without threading it through each call.
  void setSubscriptionState({
    required bool isConfigured,
    required bool isPro,
    required int freeSessionsRemaining,
  }) {
    _sink.setSuperProperties({
      'is_pro': isPro,
      'billing_configured': isConfigured,
      'free_sessions_remaining': freeSessionsRemaining,
    });
  }

  // Session.

  void appOpened() => _track('app_opened');

  // Scenario funnel.

  void scenarioViewed(Scenario scenario) =>
      _track('scenario_viewed', _scenarioProperties(scenario));

  void scenarioStarted(Scenario scenario, {required PracticeMode mode}) =>
      _track('scenario_started', {
        ..._scenarioProperties(scenario),
        'mode': mode.name,
      });

  // Simulation funnel.

  void simulationStarted(
    Scenario scenario, {
    required PracticeMode mode,
    required bool isRetry,
  }) {
    _track('simulation_started', {
      ..._scenarioProperties(scenario),
      'mode': mode.name,
      'is_retry': isRetry,
    });
    if (isRetry) _track('retry_started', _scenarioProperties(scenario));
  }

  /// One manager turn. The response itself is never sent — only how long it
  /// was and who scored it.
  void simulationMessageSent(
    Scenario scenario, {
    required PracticeMode mode,
    required int turnIndex,
    required int responseLength,
    required EvaluationSource source,
  }) => _track('simulation_message_sent', {
    ..._scenarioProperties(scenario),
    'mode': mode.name,
    'turn_index': turnIndex,
    'response_length': responseLength,
    'coach': source.name,
  });

  void simulationCompleted(
    Scenario scenario, {
    required PracticeMode mode,
    required bool isRetry,
    required int turnCount,
    required int durationSeconds,
    required PracticeSummary summary,
  }) {
    final properties = {
      ..._scenarioProperties(scenario),
      'mode': mode.name,
      'is_retry': isRetry,
      'turn_count': turnCount,
      'simulation_duration_seconds': durationSeconds,
      ..._summaryProperties(summary),
    };
    _track('simulation_completed', properties);
    if (isRetry) _track('retry_completed', properties);
  }

  /// Left before the coaching report. This is the drop-off the roadmap asks
  /// to measure, so the turn reached matters more than the fact of leaving.
  void simulationAbandoned(
    Scenario scenario, {
    required PracticeMode mode,
    required int turnReached,
    required int durationSeconds,
  }) => _track('simulation_abandoned', {
    ..._scenarioProperties(scenario),
    'mode': mode.name,
    'turn_reached': turnReached,
    'simulation_duration_seconds': durationSeconds,
  });

  void evaluationViewed(
    Scenario scenario, {
    required PracticeMode mode,
    required PracticeSummary summary,
  }) => _track('evaluation_viewed', {
    ..._scenarioProperties(scenario),
    'mode': mode.name,
    ..._summaryProperties(summary),
  });

  // Monetization funnel.

  void paywallViewed({
    required PaywallTrigger trigger,
    required String? offeringId,
    required int planCount,
  }) => _track('paywall_viewed', {
    'trigger': trigger.name,
    'paywall_id': offeringId ?? 'unavailable',
    'plan_count': planCount,
  });

  void paywallDismissed({
    required PaywallTrigger trigger,
    required String? offeringId,
  }) => _track('paywall_dismissed', {
    'trigger': trigger.name,
    'paywall_id': offeringId ?? 'unavailable',
  });

  void purchaseCompleted({
    required String packageId,
    required String? offeringId,
    required bool startedTrial,
  }) {
    final properties = {
      'package_id': packageId,
      'paywall_id': offeringId ?? 'unknown',
    };
    _track('purchase_completed', properties);
    if (startedTrial) _track('trial_started', properties);
  }

  /// [restored] is false when the account simply had nothing to restore,
  /// which is a different funnel step from a successful restore.
  void restoreCompleted({
    required bool restored,
    required RestoreSource from,
  }) => _track('restore_completed', {'restored': restored, 'from': from.name});

  void _track(String event, [Map<String, Object> properties = const {}]) {
    _sink.track(event, properties);
  }

  static Map<String, Object> _scenarioProperties(Scenario scenario) => {
    'scenario_id': scenario.id,
    'scenario_skill': scenario.skill,
    'difficulty': scenario.difficulty.name,
  };

  static Map<String, Object> _summaryProperties(PracticeSummary summary) => {
    'overall_score': summary.score,
    'clarity': summary.clarity,
    'empathy': summary.empathy,
    'courage': summary.courage,
    'coached_by_ai': summary.usedAi,
    // Not PRD §9's success/partial/unresolved/escalated — the simulation has
    // no outcome model yet. Named for what it actually is.
    'score_band': _bandFor(summary.score),
  };

  static String _bandFor(int score) => switch (score) {
    >= 82 => 'strong',
    >= 68 => 'solid',
    >= 52 => 'mixed',
    _ => 'struggled',
  };
}

/// Where someone reached the paywall from, so the forced and the voluntary
/// paths can be told apart.
enum PaywallTrigger { sessionLimit, homeUpsell, progressUpsell }

enum RestoreSource { paywall, progress }
