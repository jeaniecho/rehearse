import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/subscription.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/paywall_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/subscription_client.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/practice_history_scope.dart';
import 'package:rehearse/widgets/subscription_scope.dart';

const _annual = SubscriptionPlan(
  id: r'$rc_annual',
  period: SubscriptionPeriod.annual,
  priceLabel: r'$44.99',
  perMonthLabel: r'$3.75',
  trialLabel: '7 days free',
);

const _monthly = SubscriptionPlan(
  id: r'$rc_monthly',
  period: SubscriptionPeriod.monthly,
  priceLabel: r'$8.99',
);

const _offer = SubscriptionOffer(id: 'default', plans: [_annual, _monthly]);

Future<Subscription> subscriptionWith({
  bool configured = true,
  bool isPro = false,
  int used = 0,
  SubscriptionOffer? offer = _offer,
  SubscriptionClient? client,
  SettingsStore? store,
}) async {
  final subscription = Subscription(
    client:
        client ??
        FakeSubscriptionClient(
          configured: configured,
          isPro: isPro,
          offer: offer,
        ),
    store:
        store ?? InMemorySettingsStore({'rehearse.free_sessions_used': used}),
  );
  await subscription.load();
  return subscription;
}

void main() {
  group('the gate', () {
    test('an unconfigured build never blocks and never counts', () async {
      final subscription = await subscriptionWith(configured: false);
      addTearDown(subscription.dispose);

      expect(subscription.isConfigured, isFalse);
      expect(subscription.canStartPractice, isTrue);
      expect(subscription.showsFreeAllowance, isFalse);

      for (var i = 0; i < 5; i++) {
        await subscription.recordCompletedSession();
      }

      expect(subscription.freeSessionsUsed, 0);
      expect(subscription.canStartPractice, isTrue);
    });

    test('three completed rehearsals, then the paywall', () async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      expect(subscription.freeSessionsRemaining, 3);

      await subscription.recordCompletedSession();
      expect(subscription.freeSessionsRemaining, 2);
      expect(subscription.canStartPractice, isTrue);

      await subscription.recordCompletedSession();
      await subscription.recordCompletedSession();

      expect(subscription.freeSessionsRemaining, 0);
      expect(subscription.isPaywalled, isTrue);
    });

    test('Pro never counts and never blocks', () async {
      final subscription = await subscriptionWith(isPro: true);
      addTearDown(subscription.dispose);

      await subscription.recordCompletedSession();

      expect(subscription.freeSessionsUsed, 0);
      expect(subscription.isPaywalled, isFalse);
      expect(subscription.showsFreeAllowance, isFalse);
    });

    test('the count survives a restart', () async {
      final store = InMemorySettingsStore();
      final first = await subscriptionWith(store: store);
      await first.recordCompletedSession();
      await first.recordCompletedSession();
      first.dispose();

      final second = await subscriptionWith(store: store);
      addTearDown(second.dispose);

      expect(second.freeSessionsUsed, 2);
      expect(second.freeSessionsRemaining, 1);
    });

    test(
      'clearing practice history does not hand back free sessions',
      () async {
        final store = InMemorySettingsStore();
        final subscription = await subscriptionWith(store: store);
        addTearDown(subscription.dispose);
        final history = PracticeHistory(store: InMemoryHistoryStore());
        addTearDown(history.dispose);

        for (var i = 0; i < 3; i++) {
          await history.add(_record());
          await subscription.recordCompletedSession();
        }
        expect(subscription.isPaywalled, isTrue);

        await history.clear();

        expect(history.isEmpty, isTrue);
        expect(subscription.freeSessionsUsed, 3);
        expect(subscription.isPaywalled, isTrue);
      },
    );

    test('an unreadable store starts the allowance fresh', () async {
      final subscription = await subscriptionWith(store: _BrokenStore());
      addTearDown(subscription.dispose);

      expect(subscription.freeSessionsUsed, 0);

      // A failed write must not surface, and the count still holds in memory.
      await subscription.recordCompletedSession();
      expect(subscription.freeSessionsUsed, 1);
    });
  });

  group('purchasing', () {
    test('a completed purchase unlocks Pro', () async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);
      expect(subscription.isPaywalled, isTrue);

      final outcome = await subscription.purchase(_annual);

      expect(outcome, PurchaseOutcome.purchased);
      expect(subscription.isPro, isTrue);
      expect(subscription.isPaywalled, isFalse);
    });

    test('cancelling is not an error and changes nothing', () async {
      final client = FakeSubscriptionClient(
        purchaseOutcome: PurchaseOutcome.cancelled,
      );
      final subscription = await subscriptionWith(client: client, used: 3);
      addTearDown(subscription.dispose);

      final outcome = await subscription.purchase(_annual);

      expect(outcome, PurchaseOutcome.cancelled);
      expect(outcome.message, isNull, reason: 'cancelling needs no message');
      expect(subscription.isPro, isFalse);
      expect(subscription.isPaywalled, isTrue);
    });

    test('a pending purchase does not unlock Pro yet', () async {
      final client = FakeSubscriptionClient(
        purchaseOutcome: PurchaseOutcome.pending,
      );
      final subscription = await subscriptionWith(client: client);
      addTearDown(subscription.dispose);

      expect(await subscription.purchase(_annual), PurchaseOutcome.pending);
      expect(subscription.isPro, isFalse);
    });

    test('a thrown client error becomes a failure, not a crash', () async {
      final subscription = await subscriptionWith(client: _ThrowingClient());
      addTearDown(subscription.dispose);

      expect(await subscription.purchase(_annual), PurchaseOutcome.failed);
      expect(subscription.isPro, isFalse);
      expect(subscription.isBusy, isFalse);
    });

    test('restore brings Pro back, or reports nothing to restore', () async {
      final empty = await subscriptionWith();
      addTearDown(empty.dispose);
      expect(await empty.restore(), PurchaseOutcome.nothingToRestore);
      expect(empty.isPro, isFalse);

      final owned = await subscriptionWith(
        client: FakeSubscriptionClient(
          restoreOutcome: PurchaseOutcome.restored,
        ),
      );
      addTearDown(owned.dispose);
      expect(await owned.restore(), PurchaseOutcome.restored);
      expect(owned.isPro, isTrue);
    });

    test('a second call is refused while one is in flight', () async {
      final client = FakeSubscriptionClient(hold: true);
      final subscription = await subscriptionWith(client: client);
      addTearDown(subscription.dispose);

      final first = subscription.purchase(_annual);
      expect(subscription.isBusy, isTrue);
      expect(await subscription.purchase(_monthly), PurchaseOutcome.failed);

      client.release();
      expect(await first, PurchaseOutcome.purchased);
      expect(subscription.isBusy, isFalse);
      expect(client.purchases, [r'$rc_annual']);
    });

    test('an expiry pushed from the store revokes Pro', () async {
      final client = FakeSubscriptionClient(isPro: true);
      final subscription = await subscriptionWith(client: client);
      addTearDown(subscription.dispose);
      expect(subscription.isPro, isTrue);

      client.pushProStatus(false);

      expect(subscription.isPro, isFalse);
      expect(subscription.isPaywalled, isFalse, reason: '3 free sessions left');
    });
  });

  group('offerings', () {
    test('plans and copy come from the offering, not from code', () async {
      const remote = SubscriptionOffer(
        id: 'experiment_b',
        plans: [_monthly],
        headline: 'Be ready for tomorrow.',
        callToAction: 'Get ready',
      );
      final subscription = await subscriptionWith(offer: remote);
      addTearDown(subscription.dispose);

      expect(subscription.offer?.id, 'experiment_b');
      expect(subscription.offer?.headline, 'Be ready for tomorrow.');
      expect(subscription.offer?.plans.single.priceLabel, r'$8.99');
    });

    test('an unavailable offering leaves the offer null', () async {
      final subscription = await subscriptionWith(offer: null);
      addTearDown(subscription.dispose);

      expect(subscription.offer, isNull);
      expect(subscription.isConfigured, isTrue);
    });

    test('annual is recommended over monthly', () {
      expect(_offer.recommended, _annual);
      expect(
        const SubscriptionOffer(id: 'x', plans: [_monthly]).recommended,
        _monthly,
      );
    });
  });

  group('keys', () {
    test('no dart-define means no client, so nothing is gated', () {
      expect(RevenueCatKeys.forPlatform(TargetPlatform.iOS), isNull);
      expect(RevenueCatKeys.forPlatform(TargetPlatform.android), isNull);
      expect(createSubscriptionClient(), isA<UnconfiguredSubscriptionClient>());
    });

    test('the unconfigured client sells nothing', () async {
      const client = UnconfiguredSubscriptionClient();

      expect(await client.configure(onProChanged: (_) {}), isFalse);
      expect(await client.loadOffer(), isNull);
      expect(await client.purchase('x'), PurchaseOutcome.unavailable);
      expect(await client.restore(), PurchaseOutcome.unavailable);
    });
  });

  group('in the app', () {
    Future<void> pump(
      WidgetTester tester,
      Widget screen, {
      required Subscription subscription,
      List<PracticeRecord> records = const [],
    }) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final history = PracticeHistory(store: InMemoryHistoryStore());
      addTearDown(history.dispose);
      for (final record in records) {
        await history.add(record);
      }

      await tester.pumpWidget(
        PracticeHistoryScope(
          history: history,
          child: SubscriptionScope(
            subscription: subscription,
            child: MaterialApp(theme: AppTheme.light, home: screen),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the briefing is free to read even when paywalled', (
      tester,
    ) async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: scenarios.first),
        subscription: subscription,
      );

      expect(find.text('The slipping deadline'), findsOneWidget);
      expect(find.text('Jordan Lee'), findsOneWidget);
      expect(find.byKey(const Key('begin_simulation')), findsOneWidget);
    });

    testWidgets('starting a rehearsal past the limit opens the paywall', (
      tester,
    ) async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: scenarios.first),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byType(PracticeScreen), findsNothing);
    });

    testWidgets('closing the paywall does not start a rehearsal', (
      tester,
    ) async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: scenarios.first),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('close_paywall')));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeScreen), findsNothing);
      expect(find.text('Scenario briefing'), findsOneWidget);
    });

    testWidgets('buying Pro drops you straight into the rehearsal', (
      tester,
    ) async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: scenarios.first),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_subscription')));
      await tester.pumpAndSettle();

      expect(subscription.isPro, isTrue);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.byType(PracticeScreen), findsOneWidget);
    });

    testWidgets('under the limit, starting is not interrupted', (tester) async {
      final subscription = await subscriptionWith(used: 1);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: scenarios.first),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.byType(PracticeScreen), findsOneWidget);
    });

    testWidgets('the paywall shows store prices and the selected plan', (
      tester,
    ) async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.sessionLimit),
        subscription: subscription,
      );

      expect(find.text(r'$44.99'), findsOneWidget);
      expect(find.text(r'$8.99'), findsOneWidget);
      expect(find.text('7 days free, then \$44.99'), findsOneWidget);
      // Annual is preselected, so the trial drives the call to action.
      expect(find.text('Start my free trial'), findsOneWidget);

      await tester.tap(find.byKey(const Key(r'plan_$rc_monthly')));
      await tester.pumpAndSettle();
      expect(find.text('Unlock unlimited practice'), findsOneWidget);
    });

    testWidgets('the paywall names the pattern your own history shows', (
      tester,
    ) async {
      final subscription = await subscriptionWith(used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.sessionLimit),
        subscription: subscription,
        records: [
          _record(clarity: 80, empathy: 78, directness: 40, confidence: 40),
        ],
      );

      expect(
        find.text(
          'You tend to soften the expectation when the other person pushes back.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an unavailable offering offers a retry, not a dead end', (
      tester,
    ) async {
      final subscription = await subscriptionWith(offer: null, used: 3);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.sessionLimit),
        subscription: subscription,
      );

      expect(find.byKey(const Key('offer_unavailable')), findsOneWidget);
      expect(find.byKey(const Key('retry_offer')), findsOneWidget);
      expect(find.byKey(const Key('start_subscription')), findsNothing);
    });

    testWidgets('a cancelled purchase leaves the paywall open and quiet', (
      tester,
    ) async {
      final subscription = await subscriptionWith(
        client: FakeSubscriptionClient(
          purchaseOutcome: PurchaseOutcome.cancelled,
        ),
        used: 3,
      );
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.sessionLimit),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('start_subscription')));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byKey(const Key('paywall_notice')), findsNothing);
    });

    testWidgets('a failed purchase says so without claiming a charge', (
      tester,
    ) async {
      final subscription = await subscriptionWith(
        client: FakeSubscriptionClient(purchaseOutcome: PurchaseOutcome.failed),
        used: 3,
      );
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.sessionLimit),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('start_subscription')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('paywall_notice')), findsOneWidget);
      expect(find.textContaining('not been charged'), findsOneWidget);
    });

    testWidgets('home counts down the free rehearsals', (tester) async {
      final subscription = await subscriptionWith(used: 2);
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      expect(find.byKey(const Key('free_allowance')), findsOneWidget);
      expect(find.text('1 free rehearsal left.'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
    });

    testWidgets('home shows Pro and drops the counter once subscribed', (
      tester,
    ) async {
      final subscription = await subscriptionWith(isPro: true);
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      expect(find.text('PRO'), findsOneWidget);
      expect(find.byKey(const Key('free_allowance')), findsNothing);
    });

    testWidgets('home says nothing about plans in an unconfigured build', (
      tester,
    ) async {
      final subscription = await subscriptionWith(configured: false);
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      expect(find.byKey(const Key('free_allowance')), findsNothing);
      expect(find.text('PRO'), findsNothing);
    });

    testWidgets('restore is reachable without passing the paywall', (
      tester,
    ) async {
      final subscription = await subscriptionWith(
        client: FakeSubscriptionClient(
          restoreOutcome: PurchaseOutcome.restored,
        ),
        used: 1,
      );
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const ProgressScreen(),
        subscription: subscription,
        records: [_record()],
      );

      expect(find.byKey(const Key('plan_card')), findsOneWidget);
      expect(find.text('2 of 3 free rehearsals left.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('restore_from_progress')));
      await tester.pumpAndSettle();

      expect(subscription.isPro, isTrue);
      expect(find.text('Rehearse Pro'), findsOneWidget);
    });

    testWidgets('reaching the coaching report spends one free rehearsal', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        ResultsScreen(
          scenario: scenarios.first,
          responses: [
            for (final turn in scenarios.first.turns)
              PracticeResponse.fromChoice(turn.choices.first),
          ],
        ),
        subscription: subscription,
      );

      expect(find.text('COACHING REPORT'), findsOneWidget);
      expect(subscription.freeSessionsUsed, 1);
      expect(subscription.freeSessionsRemaining, 2);
    });

    testWidgets('a Pro rehearsal spends nothing', (tester) async {
      final subscription = await subscriptionWith(isPro: true);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        ResultsScreen(
          scenario: scenarios.first,
          responses: [
            for (final turn in scenarios.first.turns)
              PracticeResponse.fromChoice(turn.choices.first),
          ],
        ),
        subscription: subscription,
      );

      expect(subscription.freeSessionsUsed, 0);
    });

    testWidgets('the progress screen hides plans in an unconfigured build', (
      tester,
    ) async {
      final subscription = await subscriptionWith(configured: false);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const ProgressScreen(),
        subscription: subscription,
        records: [_record()],
      );

      expect(find.byKey(const Key('plan_card')), findsNothing);
      expect(find.text('Session history'), findsOneWidget);
    });
  });
}

PracticeRecord _record({
  int score = 70,
  int clarity = 70,
  int empathy = 70,
  int directness = 70,
  int confidence = 70,
}) {
  return PracticeRecord(
    scenarioId: scenarios.first.id,
    completedAt: DateTime(2026, 9, 3),
    mode: PracticeMode.guided,
    score: score,
    clarity: clarity,
    empathy: empathy,
    directness: directness,
    confidence: confidence,
    usedAi: false,
  );
}

class FakeSubscriptionClient implements SubscriptionClient {
  FakeSubscriptionClient({
    this.configured = true,
    this.isPro = false,
    this.offer = _offer,
    this.purchaseOutcome = PurchaseOutcome.purchased,
    this.restoreOutcome = PurchaseOutcome.nothingToRestore,
    this.hold = false,
  });

  final bool configured;
  final bool isPro;
  final SubscriptionOffer? offer;
  final PurchaseOutcome purchaseOutcome;
  final PurchaseOutcome restoreOutcome;

  /// Keeps a purchase in flight so re-entrancy can be observed.
  final bool hold;

  final List<String> purchases = [];
  ProStatusCallback? _onProChanged;
  Completer<void>? _gate;

  void pushProStatus(bool value) => _onProChanged?.call(value);

  void release() => _gate?.complete();

  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async {
    _onProChanged = onProChanged;
    if (configured && isPro) onProChanged(true);
    return configured;
  }

  @override
  Future<SubscriptionOffer?> loadOffer() async => configured ? offer : null;

  @override
  Future<PurchaseOutcome> purchase(String planId) async {
    purchases.add(planId);
    if (hold) {
      _gate = Completer<void>();
      await _gate!.future;
    }
    if (purchaseOutcome.unlocksPro) _onProChanged?.call(true);
    return purchaseOutcome;
  }

  @override
  Future<PurchaseOutcome> restore() async {
    if (restoreOutcome.unlocksPro) _onProChanged?.call(true);
    return restoreOutcome;
  }
}

class _ThrowingClient implements SubscriptionClient {
  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async =>
      true;

  @override
  Future<SubscriptionOffer?> loadOffer() async => _offer;

  @override
  Future<PurchaseOutcome> purchase(String planId) async =>
      throw StateError('store exploded');

  @override
  Future<PurchaseOutcome> restore() async => throw StateError('store exploded');
}

class _BrokenStore implements SettingsStore {
  @override
  Future<bool?> readBool(String key) async => throw StateError('unavailable');

  @override
  Future<void> writeBool(String key, bool value) async =>
      throw StateError('unavailable');

  @override
  Future<int?> readInt(String key) async => throw StateError('unavailable');

  @override
  Future<void> writeInt(String key, int value) async =>
      throw StateError('unavailable');
}
