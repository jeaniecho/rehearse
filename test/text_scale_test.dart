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
import 'package:rehearse/screens/tabs_screen.dart';
import 'package:rehearse/screens/you_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/models/subscription.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/subscription_client.dart';
import 'package:rehearse/services/speech_output_service.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

/// A manager with larger system text should still be able to use the app.
/// Flutter reports an overflow as a test failure, so simply laying every
/// screen out at an accessibility text size is the assertion.
void main() {
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

    final subscription = Subscription(client: _OfferingClient());
    addTearDown(subscription.dispose);
    await subscription.load();

    await tester.pumpWidget(
      RehearseScope(
        history: history,
        subscription: subscription,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: screen,
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

        // Scrolled to the end, because the rails are the part of this screen
        // whose height is a formula rather than a layout, and a ListView
        // does not build what is far below the fold. A tile that outgrows
        // its rail overflows, which is this file's whole assertion.
        await tester.fling(
          find.byType(ListView).first,
          const Offset(0, -3000),
          3000,
        );
        await tester.pumpAndSettle();
      });

      testWidgets('onboarding', (tester) async {
        await layOut(tester, const OnboardingScreen(), textScale: textScale);
      });

      for (final scenario in scenarios) {
        testWidgets('briefing ${scenario.id}', (tester) async {
          await layOut(
            tester,
            BriefScreen(scenario: scenario),
            textScale: textScale,
          );
        });
      }

      for (final scenario in scenarios) {
        testWidgets('practice ${scenario.id}', (tester) async {
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
      }

      for (final scenario in scenarios) {
        testWidgets('coaching report ${scenario.id}', (tester) async {
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
      }

      testWidgets('progress', (tester) async {
        await layOut(tester, const ProgressScreen(), textScale: textScale);
      });

      testWidgets('you', (tester) async {
        await layOut(tester, const YouScreen(), textScale: textScale);
      });

      // The tab bar is the one piece of chrome on every screen, and its
      // labels are the first thing a large scale pushes out of shape.
      testWidgets('the tab bar', (tester) async {
        await layOut(tester, const TabsScreen(), textScale: textScale);
      });

      testWidgets('paywall', (tester) async {
        await layOut(
          tester,
          const PaywallScreen(trigger: PaywallTrigger.lockedScenario),
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
