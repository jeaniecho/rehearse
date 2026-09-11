// Renders every screen at device size, with the real bundled fonts, to
// build/ui-review/.
//
//   flutter test tool/ui_review.dart
//
// For looking at, not for shipping — `generate_screenshots.dart` makes the
// store assets. This exists because the two other ways of checking layout
// each have a blind spot:
//
//   - A widget test draws text as boxes, so it can prove nothing about type.
//   - A web build has real fonts but no RevenueCat, so `isConfigured` is
//     false and it can never show a lock, a paywall, or the plan card.
//
// This has both: real fonts, and a fake store client that can be free or
// Pro. Every state below was unreachable by either other route.
//
// `flutter test` on its own does not pick this up — it runs `test/` — so
// nothing here is part of the suite.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/subscription.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/onboarding_screen.dart';
import 'package:rehearse/screens/paywall_screen.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/screens/tabs_screen.dart';
import 'package:rehearse/screens/you_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/haptics.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/subscription_client.dart';
import 'package:rehearse/widgets/illustration.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

import 'harness.dart';

/// 6.7" iPhone, the same frame the store assets use.
const _size = Size(1290, 2796);
const _ratio = 3.0;

/// Small enough to read in one go, which is the point of this tool. The
/// store generator writes at the full ratio; nothing here is submitted.
const _outputRatio = 1.4;

late HarnessFonts _fonts;

/// One free conversation and one that is not, looked up rather than named
/// so this follows the free tier if its membership is re-picked.
final _free = scenarios.firstWhere(
  (s) => Subscription.freeScenarioIds.contains(s.id),
);
final _locked = scenarios.firstWhere(
  (s) => !Subscription.freeScenarioIds.contains(s.id),
);

const _offer = SubscriptionOffer(
  id: 'default',
  plans: [
    SubscriptionPlan(
      id: r'$rc_annual',
      period: SubscriptionPeriod.annual,
      priceLabel: r'$59.99',
      perMonthLabel: r'$5.00',
      trialLabel: '7 days free',
    ),
    SubscriptionPlan(
      id: r'$rc_monthly',
      period: SubscriptionPeriod.monthly,
      priceLabel: r'$8.99',
    ),
  ],
);

/// Always configured, because an unconfigured build is the one state the
/// web preview can already show.
class _StoreClient implements SubscriptionClient {
  const _StoreClient({this.isPro = false});

  final bool isPro;

  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async {
    if (isPro) onProChanged(true);
    return true;
  }

  @override
  Future<SubscriptionOffer?> loadOffer() async => _offer;

  @override
  Future<PurchaseOutcome> purchase(String planId) async =>
      PurchaseOutcome.purchased;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.nothingToRestore;
}

void main() {
  setUpAll(() async {
    _fonts = await loadHarnessFonts();
    if (!_fonts.brandLoaded) {
      throw StateError(
        'the bundled typeface did not load — every glyph would be a box, '
        'and there would be nothing here worth looking at',
      );
    }
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    bool isPro = false,
    bool seedHistory = true,
    double textScale = 1.0,
  }) async {
    final history = PracticeHistory(store: InMemoryHistoryStore());
    final settings = AppSettings(
      store: InMemorySettingsStore({'rehearse.onboarding_completed': true}),
    );
    final subscription = Subscription(client: _StoreClient(isPro: isPro));
    await settings.load();
    await subscription.load();
    addTearDown(history.dispose);
    addTearDown(settings.dispose);
    addTearDown(subscription.dispose);

    if (seedHistory) {
      for (var day = 0; day < 4; day++) {
        await history.add(
          PracticeRecord(
            scenarioId: [_free.id, _locked.id][day % 2],
            completedAt: DateTime.now().subtract(Duration(days: day)),
            mode: PracticeMode.freestyle,
            score: 62 + day * 6,
            clarity: 58 + day * 5,
            empathy: 81,
            directness: 54 + day * 7,
            confidence: 63,
            usedAi: true,
          ),
        );
      }
    }

    sizeAsDevice(tester, _size, _ratio);
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: RehearseScope(
          history: history,
          settings: settings,
          subscription: subscription,
          analytics: Analytics(sink: const NoopAnalyticsSink()),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _fonts.theme,
            // The real `MediaQueryData` with the scale changed, not a
            // fresh one: a bare `MediaQueryData` has a zero size and no
            // insets, so every screen under it draws as though the window
            // were empty — which is how a control sized from the screen
            // came out with no height at all in these shots.
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: screen,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The marks decode off the clock this test controls, so they are blank
    // until something actually awaits them.
    await tester.runAsync(
      () => Illustration.precacheAll(tester.element(find.byType(MaterialApp))),
    );
    await tester.pumpAndSettle();

    await writePng(
      tester,
      boundary,
      'build/ui-review/$name.png',
      pixelRatio: _outputRatio,
    );
  }

  // Home, in the three states that differ.
  testWidgets('home — free', (t) async {
    await shoot(t, '01-home-free', const TabsScreen());
  });
  testWidgets('home — pro', (t) async {
    await shoot(t, '02-home-pro', const TabsScreen(), isPro: true);
  });
  testWidgets('home — first run', (t) async {
    await shoot(t, '03-home-first-run', const TabsScreen(), seedHistory: false);
  });

  // The briefing, either side of the gate.
  testWidgets('brief — locked', (t) async {
    await shoot(t, '04-brief-locked', BriefScreen(scenario: _locked));
  });
  testWidgets('brief — free', (t) async {
    await shoot(t, '05-brief-free', BriefScreen(scenario: _free));
  });

  testWidgets('paywall', (t) async {
    await shoot(
      t,
      '06-paywall',
      const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
    );
  });

  testWidgets('you — free', (t) async {
    await shoot(t, '07-you-free', const YouScreen());
  });
  testWidgets('you — pro', (t) async {
    await shoot(t, '08-you-pro', const YouScreen(), isPro: true);
  });

  testWidgets('progress', (t) async {
    await shoot(t, '09-progress', const TabsScreen(initialTab: 1));
  });
  testWidgets('progress — empty', (t) async {
    // Centred rather than scrolling, so it is the one layout in the tabs
    // that cannot move out from under the floating capsule.
    await shoot(
      t,
      '09b-progress-empty',
      const TabsScreen(initialTab: 1),
      seedHistory: false,
    );
  });

  testWidgets('practice', (t) async {
    await shoot(
      t,
      '10-practice',
      PracticeScreen(
        scenario: _free,
        mode: PracticeMode.freestyle,
        coachService: OfflineCoachService(),
      ),
    );
  });

  // Guided: the three authored answers, which is the state the freestyle
  // shot above cannot show.
  testWidgets('practice — guided', (t) async {
    await shoot(
      t,
      '10b-practice-guided',
      PracticeScreen(
        scenario: _free,
        mode: PracticeMode.guided,
        coachService: OfflineCoachService(),
      ),
    );
  });

  testWidgets('results', (t) async {
    await shoot(
      t,
      '11-results',
      ResultsScreen(
        scenario: _free,
        mode: PracticeMode.freestyle,
        // The count-up has already finished by the time this is captured;
        // the fake keeps the render off a platform channel.
        haptics: SilentHaptics(),
        summary: PracticeSummary.fromResponses([
          for (final turn in _free.turns)
            PracticeResponse.fromChoice(turn.choices.first, turn),
        ]),
      ),
    );
  });

  // The same report without a score, which is what a guided rehearsal gets.
  testWidgets('results — guided', (t) async {
    await shoot(
      t,
      '11b-results-guided',
      ResultsScreen(
        scenario: _free,
        haptics: SilentHaptics(),
        summary: PracticeSummary.fromResponses([
          for (final turn in _free.turns)
            PracticeResponse.fromChoice(turn.choices.first, turn),
        ]),
      ),
    );
  });

  testWidgets('onboarding', (t) async {
    await shoot(t, '12-onboarding', const OnboardingScreen());
  });

  // The accessibility size that has caught the most: `text_scale_test.dart`
  // proves nothing overflows, which is not the same as it reading well.
  for (final (name, screen) in <(String, Widget)>[
    ('home', TabsScreen()),
    ('you', YouScreen()),
  ]) {
    testWidgets('$name — 1.6x text', (t) async {
      await shoot(t, '13-$name-1.6x', screen, textScale: 1.6);
    });
  }
}
