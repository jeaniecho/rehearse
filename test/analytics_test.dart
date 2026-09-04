import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/app.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/subscription.dart';
import 'package:rehearse/screens/paywall_screen.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/subscription_client.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

/// A distinctive phrase typed as a manager response. Nothing resembling it
/// may ever reach an analytics payload.
const _secret = 'Jordan, the pangolin handoff on Thursday was the third one.';

void main() {
  final scenario = scenarios.first;

  group('the funnel', () {
    late RecordingSink sink;
    late Analytics analytics;

    setUp(() async {
      sink = RecordingSink();
      analytics = Analytics(sink: sink);
      await analytics.start();
    });

    tearDown(() => analytics.dispose());

    test('is enabled only when the sink configures', () async {
      expect(analytics.isEnabled, isTrue);

      final off = Analytics(sink: const NoopAnalyticsSink());
      addTearDown(off.dispose);
      await off.start();
      expect(off.isEnabled, isFalse);

      // Calls on a disabled facade are silent no-ops, not errors.
      off.appOpened();
      off.scenarioViewed(scenario);
    });

    test('every scenario event carries the catalog identity', () {
      analytics.scenarioViewed(scenario);

      expect(sink.names, ['scenario_viewed']);
      expect(sink.last.properties, {
        'scenario_id': 'missed-deadlines',
        'scenario_skill': 'Clear feedback',
        // The scenario's own weight. The level the manager picked is a
        // separate property, because they answer different questions.
        'scenario_stakes': 'challenging',
      });
    });

    test('a retry emits both the simulation and the retry step', () {
      analytics.simulationStarted(
        scenario,
        mode: PracticeMode.guided,
        difficulty: SimulationDifficulty.veryDefensive,
        isRetry: true,
      );

      expect(sink.names, ['simulation_started', 'retry_started']);
      expect(sink.eventNamed('simulation_started')['is_retry'], isTrue);
    });

    test('a first attempt does not emit a retry step', () {
      analytics.simulationStarted(
        scenario,
        mode: PracticeMode.guided,
        difficulty: SimulationDifficulty.calm,
        isRetry: false,
      );

      expect(sink.names, ['simulation_started']);
    });

    test('completion carries duration, turns, and the score breakdown', () {
      analytics.simulationCompleted(
        scenario,
        mode: PracticeMode.freestyle,
        isRetry: false,
        turnCount: 3,
        durationSeconds: 214,
        summary: const PracticeSummary(
          score: 74,
          clarity: 66,
          empathy: 90,
          directness: 58,
          confidence: 58,
          usedAi: true,
        ),
      );

      final event = sink.eventNamed('simulation_completed');
      expect(event['turn_count'], 3);
      expect(event['simulation_duration_seconds'], 214);
      expect(event['overall_score'], 74);
      expect(event['empathy'], 90);
      expect(event['coached_by_ai'], isTrue);
      expect(event['score_band'], 'solid');
    });

    test('the score band tracks the report bands', () {
      for (final (score, band) in [
        (90, 'strong'),
        (70, 'solid'),
        (55, 'mixed'),
        (30, 'struggled'),
      ]) {
        analytics.evaluationViewed(
          scenario,
          mode: PracticeMode.guided,
          summary: PracticeSummary(
            score: score,
            clarity: score,
            empathy: score,
            directness: score,
            confidence: score,
            usedAi: false,
          ),
        );
        expect(sink.last.properties['score_band'], band);
      }
    });

    test('a purchase with a trial emits both steps', () {
      analytics.purchaseCompleted(
        packageId: r'$rc_annual',
        offeringId: 'default',
        startedTrial: true,
      );

      expect(sink.names, ['purchase_completed', 'trial_started']);
      expect(sink.last.properties['package_id'], r'$rc_annual');
      expect(sink.last.properties['paywall_id'], 'default');
    });

    test('a purchase without a trial emits only the purchase', () {
      analytics.purchaseCompleted(
        packageId: r'$rc_monthly',
        offeringId: 'default',
        startedTrial: false,
      );

      expect(sink.names, ['purchase_completed']);
    });

    test('a restore that found nothing is still a funnel step', () {
      analytics.restoreCompleted(restored: false, from: RestoreSource.progress);

      expect(sink.last.properties, {'restored': false, 'from': 'progress'});
    });

    test('entitlement rides along on every later event', () {
      analytics.setSubscriptionState(
        isConfigured: true,
        isPro: false,
        freeSessionsRemaining: 2,
      );

      expect(sink.superProperties, {
        'is_pro': false,
        'billing_configured': true,
        'free_sessions_remaining': 2,
      });
    });
  });

  group('in the app', () {
    Future<(RecordingSink, Subscription)> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sink = RecordingSink();
      final analytics = Analytics(sink: sink);
      addTearDown(analytics.dispose);
      final history = PracticeHistory(store: InMemoryHistoryStore());
      addTearDown(history.dispose);
      final subscription = Subscription(store: InMemorySettingsStore());
      addTearDown(subscription.dispose);
      final settings = AppSettings(
        store: InMemorySettingsStore({'rehearse.onboarding_completed': true}),
      );
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        RehearseApp(
          history: history,
          subscription: subscription,
          settings: settings,
          analytics: analytics,
        ),
      );
      await tester.pumpAndSettle();
      return (sink, subscription);
    }

    testWidgets('a full guided rehearsal walks the PRD funnel in order', (
      tester,
    ) async {
      final (sink, _) = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('start_recommended')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, -1000),
        1200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mode_guided')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();

      for (var turn = 0; turn < scenario.turns.length; turn++) {
        await tester.tap(find.byKey(const Key('choice_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('continue_practice')));
        await tester.pumpAndSettle();
      }

      expect(sink.names, [
        'app_opened',
        'scenario_viewed',
        'scenario_started',
        'simulation_started',
        'simulation_message_sent',
        'simulation_message_sent',
        'simulation_message_sent',
        'simulation_completed',
        'evaluation_viewed',
      ]);

      final completed = sink.eventNamed('simulation_completed');
      expect(completed['turn_count'], 3);
      expect(completed['mode'], 'guided');
      expect(completed['is_retry'], isFalse);
    });

    testWidgets('leaving mid-rehearsal records where the drop-off happened', (
      tester,
    ) async {
      final (sink, _) = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('start_recommended')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, -1000),
        1200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mode_guided')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();

      // Answer one turn, then walk out.
      await tester.tap(find.byKey(const Key('choice_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continue_practice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Leave practice'));
      await tester.pumpAndSettle();

      final abandoned = sink.eventNamed('simulation_abandoned');
      expect(abandoned['turn_reached'], 2);
      expect(abandoned['scenario_id'], 'missed-deadlines');
      expect(sink.names, isNot(contains('simulation_completed')));
      expect(sink.names, isNot(contains('evaluation_viewed')));
    });

    testWidgets('finishing does not also count as abandoning', (tester) async {
      final (sink, _) = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('start_recommended')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, -1000),
        1200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mode_guided')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();
      for (var turn = 0; turn < scenario.turns.length; turn++) {
        await tester.tap(find.byKey(const Key('choice_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('continue_practice')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('finish_practice')));
      await tester.pumpAndSettle();

      expect(sink.names, isNot(contains('simulation_abandoned')));
    });

    testWidgets('a retry is measured as its own attempt', (tester) async {
      final (sink, _) = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('start_recommended')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, -1000),
        1200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mode_guided')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();
      for (var turn = 0; turn < scenario.turns.length; turn++) {
        await tester.tap(find.byKey(const Key('choice_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('continue_practice')));
        await tester.pumpAndSettle();
      }

      sink.clear();
      await tester.scrollUntilVisible(
        find.byKey(const Key('retry_scenario')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('retry_scenario')));
      await tester.pumpAndSettle();

      expect(sink.names, contains('retry_started'));
      expect(sink.eventNamed('simulation_started')['is_retry'], isTrue);
    });
  });

  group('the paywall funnel', () {
    Future<RecordingSink> pumpPaywall(
      WidgetTester tester, {
      required PaywallTrigger trigger,
      SubscriptionOffer? offer = const SubscriptionOffer(
        id: 'default',
        plans: [
          SubscriptionPlan(
            id: r'$rc_annual',
            period: SubscriptionPeriod.annual,
            priceLabel: r'$44.99',
            trialLabel: '7 days free',
          ),
        ],
      ),
    }) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sink = RecordingSink();
      final analytics = Analytics(sink: sink);
      addTearDown(analytics.dispose);
      final subscription = Subscription(
        client: _StubClient(offer),
        store: InMemorySettingsStore(),
      );
      addTearDown(subscription.dispose);
      await subscription.load();

      await tester.pumpWidget(
        RehearseScope(
          analytics: analytics,
          subscription: subscription,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PaywallScreen(trigger: trigger),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return sink;
    }

    testWidgets('a forced paywall is distinguishable from a voluntary one', (
      tester,
    ) async {
      final sink = await pumpPaywall(
        tester,
        trigger: PaywallTrigger.sessionLimit,
      );

      final viewed = sink.eventNamed('paywall_viewed');
      expect(viewed['trigger'], 'sessionLimit');
      expect(viewed['paywall_id'], 'default');
      expect(viewed['plan_count'], 1);
    });

    testWidgets('an upsell from home is tagged as such', (tester) async {
      final sink = await pumpPaywall(
        tester,
        trigger: PaywallTrigger.homeUpsell,
      );

      expect(sink.eventNamed('paywall_viewed')['trigger'], 'homeUpsell');
    });

    testWidgets('a paywall with nothing to sell still records the view', (
      tester,
    ) async {
      final sink = await pumpPaywall(
        tester,
        trigger: PaywallTrigger.sessionLimit,
        offer: null,
      );

      final viewed = sink.eventNamed('paywall_viewed');
      expect(viewed['paywall_id'], 'unavailable');
      expect(viewed['plan_count'], 0);
    });

    testWidgets('closing records a dismissal', (tester) async {
      final sink = await pumpPaywall(
        tester,
        trigger: PaywallTrigger.sessionLimit,
      );
      await tester.tap(find.byKey(const Key('close_paywall')));
      await tester.pumpAndSettle();

      expect(sink.names, ['paywall_viewed', 'paywall_dismissed']);
    });

    testWidgets('buying records the purchase and the trial, not a dismissal', (
      tester,
    ) async {
      final sink = await pumpPaywall(
        tester,
        trigger: PaywallTrigger.sessionLimit,
      );
      await tester.tap(find.byKey(const Key('start_subscription')));
      await tester.pumpAndSettle();

      expect(sink.names, [
        'paywall_viewed',
        'purchase_completed',
        'trial_started',
      ]);
      expect(
        sink.eventNamed('purchase_completed')['package_id'],
        r'$rc_annual',
      );
    });

    testWidgets('restoring from the paywall is attributed to the paywall', (
      tester,
    ) async {
      final sink = await pumpPaywall(
        tester,
        trigger: PaywallTrigger.sessionLimit,
      );
      await tester.tap(find.byKey(const Key('restore_purchases')));
      await tester.pumpAndSettle();

      final restored = sink.eventNamed('restore_completed');
      expect(restored['from'], 'paywall');
      expect(restored['restored'], isFalse);
    });
  });

  group('privacy', () {
    testWidgets('a typed response never reaches an analytics payload', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sink = RecordingSink();
      final analytics = Analytics(sink: sink);
      addTearDown(analytics.dispose);
      await analytics.start();

      await tester.pumpWidget(
        RehearseScope(
          analytics: analytics,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PracticeScreen(
              scenario: scenario,
              mode: PracticeMode.freestyle,
              coachService: OfflineCoachService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('freeform_response')),
        _secret,
      );
      await tester.tap(find.byKey(const Key('submit_response')));
      await tester.pumpAndSettle();

      expect(sink.events, isNotEmpty, reason: 'the funnel should have fired');

      final dump = sink.events.toString();
      expect(dump, isNot(contains('pangolin')));
      expect(dump, isNot(contains(_secret)));

      // The employee's authored line is content too, and must not leak.
      expect(dump, isNot(contains(scenario.openingLine)));
      expect(dump, isNot(contains(scenario.turns.first.choices.first.text)));

      // Only the length of what was written is recorded.
      final sent = sink.eventNamed('simulation_message_sent');
      expect(sent['response_length'], _secret.length);
    });

    test('no facade method accepts free text', () {
      // A guard on the shape of the API rather than one call: every property
      // value emitted is a scalar, and the string ones are ids or enum names
      // drawn from the catalog, never anything a person typed.
      final sink = RecordingSink();
      final analytics = Analytics(sink: sink);
      addTearDown(analytics.dispose);

      analytics.scenarioViewed(scenario);
      analytics.scenarioStarted(
        scenario,
        mode: PracticeMode.freestyle,
        difficulty: SimulationDifficulty.defensive,
      );
      analytics.simulationMessageSent(
        scenario,
        mode: PracticeMode.freestyle,
        turnIndex: 0,
        responseLength: 120,
        source: EvaluationSource.offline,
      );

      const allowed = {
        'missed-deadlines',
        'Clear feedback',
        'challenging',
        'freestyle',
        'offline',
        'defensive',
      };
      for (final event in sink.events) {
        for (final value in event.properties.values) {
          if (value is String) {
            expect(
              allowed,
              contains(value),
              reason: '"$value" is not catalog metadata',
            );
          } else {
            expect(value, anyOf(isA<num>(), isA<bool>()));
          }
        }
      }
    });
  });
}

class _StubClient implements SubscriptionClient {
  _StubClient(this.offer);

  final SubscriptionOffer? offer;
  ProStatusCallback? _onProChanged;

  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async {
    _onProChanged = onProChanged;
    return true;
  }

  @override
  Future<SubscriptionOffer?> loadOffer() async => offer;

  @override
  Future<PurchaseOutcome> purchase(String planId) async {
    _onProChanged?.call(true);
    return PurchaseOutcome.purchased;
  }

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.nothingToRestore;
}

class RecordedEvent {
  const RecordedEvent(this.name, this.properties);

  final String name;
  final Map<String, Object> properties;

  @override
  String toString() => '$name $properties';
}

class RecordingSink implements AnalyticsSink {
  final List<RecordedEvent> events = [];
  final Map<String, Object> superProperties = {};

  List<String> get names => [for (final event in events) event.name];

  RecordedEvent get last => events.last;

  Map<String, Object> eventNamed(String name) =>
      events.firstWhere((event) => event.name == name).properties;

  void clear() => events.clear();

  @override
  Future<bool> configure() async => true;

  @override
  Future<void> track(String event, Map<String, Object> properties) async {
    events.add(RecordedEvent(event, properties));
  }

  @override
  Future<void> setSuperProperties(Map<String, Object> properties) async {
    superProperties.addAll(properties);
  }
}
