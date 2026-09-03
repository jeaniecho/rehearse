import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/onboarding_screen.dart';
import 'package:rehearse/screens/paywall_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/models/subscription.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/subscription_client.dart';
import 'package:rehearse/widgets/subscription_scope.dart';
import 'package:rehearse/services/speech_output_service.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/practice_history_scope.dart';

/// A manager with larger system text should still be able to use the app.
/// Flutter reports an overflow as a test failure, so simply laying every
/// screen out at an accessibility text size is the assertion.
void main() {
  final scenario = scenarios.first;

  Future<void> layOut(
    WidgetTester tester,
    Widget screen, {
    required double textScale,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final history = PracticeHistory(store: InMemoryHistoryStore());
    addTearDown(history.dispose);
    for (var day = 0; day < 4; day++) {
      await history.add(
        PracticeRecord(
          scenarioId: scenarios[day % scenarios.length].id,
          completedAt: DateTime.now().subtract(Duration(days: day)),
          mode: PracticeMode.freestyle,
          score: 55 + day * 9,
          clarity: 61,
          empathy: 78,
          directness: 47,
          confidence: 47,
          usedAi: true,
        ),
      );
    }

    final subscription = Subscription(
      client: _OfferingClient(),
      store: InMemorySettingsStore(),
    );
    addTearDown(subscription.dispose);
    await subscription.load();

    await tester.pumpWidget(
      PracticeHistoryScope(
        history: history,
        child: SubscriptionScope(
          subscription: subscription,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: screen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final textScale in [1.0, 1.3, 1.6]) {
    group('at ${textScale}x text', () {
      testWidgets('home', (tester) async {
        await layOut(tester, const HomeScreen(), textScale: textScale);
      });

      testWidgets('onboarding', (tester) async {
        await layOut(tester, const OnboardingScreen(), textScale: textScale);
      });

      testWidgets('briefing', (tester) async {
        await layOut(
          tester,
          BriefScreen(scenario: scenario),
          textScale: textScale,
        );
      });

      testWidgets('practice', (tester) async {
        await layOut(
          tester,
          PracticeScreen(
            scenario: scenario,
            mode: PracticeMode.freestyle,
            coachService: OfflineCoachService(),
            speechOutputService: _SilentVoice(),
          ),
          textScale: textScale,
        );
      });

      testWidgets('coaching report', (tester) async {
        await layOut(
          tester,
          ResultsScreen(
            scenario: scenario,
            summary: PracticeSummary.fromResponses([
              for (final turn in scenario.turns)
                PracticeResponse.fromChoice(turn.choices.first, turn),
            ]),
          ),
          textScale: textScale,
        );
      });

      testWidgets('progress', (tester) async {
        await layOut(tester, const ProgressScreen(), textScale: textScale);
      });

      testWidgets('paywall', (tester) async {
        await layOut(
          tester,
          const PaywallScreen(trigger: PaywallTrigger.sessionLimit),
          textScale: textScale,
        );
      });
    });
  }
}

/// A store with a realistic offering, so the paywall lays out with prices
/// rather than its unavailable state.
class _OfferingClient implements SubscriptionClient {
  @override
  Future<bool> configure({required ProStatusCallback onProChanged}) async =>
      true;

  @override
  Future<SubscriptionOffer?> loadOffer() async => const SubscriptionOffer(
    id: 'default',
    plans: [
      SubscriptionPlan(
        id: 'annual',
        period: SubscriptionPeriod.annual,
        priceLabel: r'$44.99',
        perMonthLabel: r'$3.75',
        trialLabel: '7 days free',
      ),
      SubscriptionPlan(
        id: 'monthly',
        period: SubscriptionPeriod.monthly,
        priceLabel: r'$8.99',
      ),
    ],
  );

  @override
  Future<PurchaseOutcome> purchase(String planId) async =>
      PurchaseOutcome.purchased;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.nothingToRestore;
}

class _SilentVoice implements SpeechOutputService {
  @override
  Future<bool> initialize({
    required SpeakingStateCallback onSpeakingChanged,
  }) async => false;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
