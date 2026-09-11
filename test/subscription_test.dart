import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/subscription.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/data/legal_links.dart';
import 'package:rehearse/screens/paywall_screen.dart';
import 'package:rehearse/services/link_service.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/you_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/subscription_client.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

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
  SubscriptionOffer? offer = _offer,
  SubscriptionClient? client,
}) async {
  final subscription = Subscription(
    client:
        client ??
        FakeSubscriptionClient(
          configured: configured,
          isPro: isPro,
          offer: offer,
        ),
  );
  await subscription.load();
  return subscription;
}

/// A conversation the free tier includes, and one it does not.
///
/// Looked up rather than named, so these follow the free tier if its
/// membership is ever re-picked. Which ids are free is asserted separately,
/// in `scenarios_test.dart`.
final _freeScenario = scenarios.firstWhere(
  (s) => Subscription.freeScenarioIds.contains(s.id),
);
final _lockedScenario = scenarios.firstWhere(
  (s) => !Subscription.freeScenarioIds.contains(s.id),
);

void main() {
  group('the gate', () {
    test('an unconfigured build never locks anything', () async {
      final subscription = await subscriptionWith(configured: false);
      addTearDown(subscription.dispose);

      expect(subscription.isConfigured, isFalse);
      expect(subscription.showsLocks, isFalse);
      for (final scenario in scenarios) {
        expect(subscription.isLocked(scenario), isFalse, reason: scenario.id);
      }
    });

    test(
      'a free account reaches the free conversations and no others',
      () async {
        final subscription = await subscriptionWith();
        addTearDown(subscription.dispose);

        expect(subscription.showsLocks, isTrue);
        expect(subscription.canPractice(_freeScenario), isTrue);
        expect(subscription.isLocked(_lockedScenario), isTrue);
      },
    );

    test('the free conversations are exactly the named ids', () async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      final open = scenarios
          .where((s) => !subscription.isLocked(s))
          .map((s) => s.id)
          .toSet();

      expect(open, Subscription.freeScenarioIds);
    });

    test('Pro unlocks the whole library', () async {
      final subscription = await subscriptionWith(isPro: true);
      addTearDown(subscription.dispose);

      expect(subscription.showsLocks, isFalse);
      for (final scenario in scenarios) {
        expect(subscription.isLocked(scenario), isFalse, reason: scenario.id);
      }
    });

    test('a free conversation repeats without limit', () async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);
      final history = PracticeHistory(store: InMemoryHistoryStore());
      addTearDown(history.dispose);

      // The gate used to be a lifetime count of completed rehearsals, so
      // this is the case that changed: finishing many does not close it.
      for (var i = 0; i < 25; i++) {
        await history.add(_record());
      }

      expect(subscription.canPractice(_freeScenario), isTrue);
    });

    test('the gate holds no state, so it survives a reinstall', () async {
      // Nothing is written, so a fresh Subscription over a fresh store is
      // indistinguishable from one that has been used — which is the whole
      // reason this is a content gate rather than a count.
      final first = await subscriptionWith();
      final second = await subscriptionWith();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      for (final scenario in scenarios) {
        expect(
          first.isLocked(scenario),
          second.isLocked(scenario),
          reason: scenario.id,
        );
      }
    });
  });

  group('purchasing', () {
    test('a completed purchase unlocks Pro', () async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);
      expect(subscription.isLocked(_lockedScenario), isTrue);

      final outcome = await subscription.purchase(_annual);

      expect(outcome, PurchaseOutcome.purchased);
      expect(subscription.isPro, isTrue);
      expect(subscription.isLocked(_lockedScenario), isFalse);
    });

    test('cancelling is not an error and changes nothing', () async {
      final client = FakeSubscriptionClient(
        purchaseOutcome: PurchaseOutcome.cancelled,
      );
      final subscription = await subscriptionWith(client: client);
      addTearDown(subscription.dispose);

      final outcome = await subscription.purchase(_annual);

      expect(outcome, PurchaseOutcome.cancelled);
      expect(outcome.message, isNull, reason: 'cancelling needs no message');
      expect(subscription.isPro, isFalse);
      expect(subscription.isLocked(_lockedScenario), isTrue);
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
      expect(
        subscription.isLocked(_lockedScenario),
        isTrue,
        reason: 'losing Pro closes the library again',
      );
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
        RehearseScope(
          history: history,
          subscription: subscription,
          child: MaterialApp(theme: AppTheme.light, home: screen),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the briefing is free to read even when paywalled', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: _lockedScenario),
        subscription: subscription,
      );

      // Read off the scenario rather than written out, because which one is
      // locked follows the free tier — see `_lockedScenario`.
      expect(find.text(_lockedScenario.title), findsOneWidget);
      expect(find.text(_lockedScenario.personName), findsOneWidget);
      expect(find.byKey(const Key('begin_simulation')), findsOneWidget);
    });

    testWidgets('starting a rehearsal past the limit opens the paywall', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: _lockedScenario),
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
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: _lockedScenario),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('close_paywall')));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeScreen), findsNothing);
      expect(find.byType(BriefScreen), findsOneWidget);
    });

    testWidgets('buying Pro drops you straight into the rehearsal', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: _lockedScenario),
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

    testWidgets('a free conversation starts without interruption', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        BriefScreen(scenario: _freeScenario),
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
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
        subscription: subscription,
      );

      expect(find.text(r'$44.99'), findsOneWidget);
      expect(find.text(r'$8.99'), findsOneWidget);
      expect(find.text('7 days free, then \$44.99'), findsOneWidget);
      // Annual is preselected, so the trial drives the call to action.
      expect(find.text('Start my free trial'), findsOneWidget);

      await tester.tap(find.byKey(const Key(r'plan_$rc_monthly')));
      await tester.pumpAndSettle();
      expect(find.text('Unlock all conversations'), findsOneWidget);
    });

    // Apple 3.1.2: an auto-renewing subscription has to link both documents
    // from the point of purchase. Losing these is a rejection, not a nitpick.
    testWidgets('the paywall links the terms and the privacy policy', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);
      final links = FakeLinkService();

      await pump(
        tester,
        PaywallScreen(trigger: PaywallTrigger.lockedScenario, links: links),
        subscription: subscription,
      );

      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      await tester.tap(find.byKey(const Key('paywall_terms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('paywall_privacy')));
      await tester.pumpAndSettle();

      expect(links.opened, [LegalLinks.terms, LegalLinks.privacy]);
      expect(
        links.opened.every((url) => url.scheme == 'https'),
        isTrue,
        reason: 'the store will not accept an unreachable policy link',
      );
    });

    testWidgets('a link that will not open says so', (tester) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        PaywallScreen(
          trigger: PaywallTrigger.lockedScenario,
          links: FakeLinkService(succeeds: false),
        ),
        subscription: subscription,
      );

      await tester.tap(find.byKey(const Key('paywall_privacy')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not open that page'), findsOneWidget);
    });

    testWidgets('the paywall names the pattern your own history shows', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
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
      final subscription = await subscriptionWith(offer: null);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
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
      );
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
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
      );
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
        subscription: subscription,
      );
      await tester.tap(find.byKey(const Key('start_subscription')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('paywall_notice')), findsOneWidget);
      expect(find.textContaining('not been charged'), findsOneWidget);
    });

    testWidgets('home offers Pro without shouting it', (tester) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      expect(find.byKey(const Key('pro_upsell')), findsOneWidget);
      expect(find.text('Unlock all conversations'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
    });

    testWidgets('home recommends a conversation a free account can start', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      // The primary call to action must not open a paywall on first run.
      await tester.tap(find.byKey(const Key('start_recommended')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin_simulation')));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.byType(PracticeScreen), findsOneWidget);
    });

    testWidgets('locked conversations are marked as Pro on home', (
      tester,
    ) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);
      // The mark is a padlock now, so what is asserted is the label it
      // carries for anyone who cannot see one. The handle is disposed here
      // rather than in a tear-down: the framework checks for live handles
      // before tear-downs run.
      final semantics = tester.ensureSemantics();

      await pump(tester, const HomeScreen(), subscription: subscription);

      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      // The tile merges its own label with the chip's, so the assertion is
      // that the word is in there, not that it stands alone.
      expect(find.bySemanticsLabel(RegExp(r'\bPro\b')), findsWidgets);

      semantics.dispose();
    });

    testWidgets('home shows Pro and drops the free line once subscribed', (
      tester,
    ) async {
      final subscription = await subscriptionWith(isPro: true);
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      // Pro is worn on the profile button rather than announced beside the
      // wordmark, so the medal is the assertion.
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.byKey(const Key('pro_upsell')), findsNothing);
    });

    testWidgets('home says nothing about plans in an unconfigured build', (
      tester,
    ) async {
      final subscription = await subscriptionWith(configured: false);
      addTearDown(subscription.dispose);

      await pump(tester, const HomeScreen(), subscription: subscription);

      expect(find.byKey(const Key('pro_upsell')), findsNothing);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
    });

    testWidgets('restore is reachable without passing the paywall', (
      tester,
    ) async {
      final subscription = await subscriptionWith(
        client: FakeSubscriptionClient(
          restoreOutcome: PurchaseOutcome.restored,
        ),
      );
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const YouScreen(),
        subscription: subscription,
        records: [_record()],
      );

      expect(find.byKey(const Key('plan_card')), findsOneWidget);
      expect(
        find.text(
          '${Subscription.freeScenarioIds.length} conversations, '
          'unlimited reps.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('restore_from_settings')));
      await tester.pumpAndSettle();

      expect(subscription.isPro, isTrue);
      expect(find.text('Rehearse Pro'), findsOneWidget);
    });

    testWidgets('finishing a rehearsal costs nothing', (tester) async {
      final subscription = await subscriptionWith();
      addTearDown(subscription.dispose);

      await pump(
        tester,
        ResultsScreen(
          scenario: _freeScenario,
          summary: PracticeSummary.fromResponses([
            for (final turn in _freeScenario.turns)
              PracticeResponse.fromChoice(turn.choices.first, turn),
          ]),
        ),
        subscription: subscription,
      );

      expect(find.text('COACHING REPORT'), findsOneWidget);
      // The report used to be where a free session was spent. Nothing is
      // spent now, so the same conversation is open again immediately.
      expect(subscription.canPractice(_freeScenario), isTrue);
      expect(subscription.isLocked(_lockedScenario), isTrue);
    });

    testWidgets('the You tab hides plans in an unconfigured build', (
      tester,
    ) async {
      final subscription = await subscriptionWith(configured: false);
      addTearDown(subscription.dispose);

      await pump(
        tester,
        const YouScreen(),
        subscription: subscription,
        records: [_record()],
      );

      expect(find.byKey(const Key('plan_card')), findsNothing);
      // The rest of the tab is still there — an unconfigured build has no
      // plan to talk about, not nothing to say.
      expect(find.byKey(const Key('clear_history')), findsOneWidget);
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
