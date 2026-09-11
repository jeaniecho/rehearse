// Renders App Store / Play screenshots from the real app.
//
//   flutter test tool/generate_screenshots.dart
//
// Output lands in build/screenshots/. Run as a test because that is the
// supported way to get a real Flutter canvas outside a running app.
//
// These are the actual screens with seeded data, not mockups — if the UI
// changes, so do the screenshots, which is the whole point.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/onboarding_screen.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/tabs_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/widgets/illustration.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

import 'harness.dart';

/// 6.7" iPhone — the size App Store Connect requires. Play accepts it too.
const _size = Size(1290, 2796);
const _ratio = 3.0;

final _scenario = scenarios.first;

/// The device exactly, for both stores.
late HarnessFonts _fonts;

void main() {
  late PracticeHistory history;
  late AppSettings settings;
  late Subscription subscription;

  setUpAll(() async {
    _fonts = await loadHarnessFonts();
    if (!_fonts.brandLoaded) {
      stdout.writeln(
        'WARNING: the bundled typeface did not load — glyphs will render '
        'as boxes and these images must not be submitted.',
      );
    }
  });

  setUp(() async {
    history = PracticeHistory(store: InMemoryHistoryStore());
    settings = AppSettings(
      store: InMemorySettingsStore({'rehearse.onboarding_completed': true}),
    );
    subscription = Subscription();
    await settings.load();
    await subscription.load();

    // Enough history that the home screen shows momentum rather than the
    // first-run state. A screenshot of an empty app sells nothing.
    for (var day = 0; day < 4; day++) {
      await history.add(
        PracticeRecord(
          scenarioId: scenarios[day % scenarios.length].id,
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
  });

  tearDown(() {
    history.dispose();
    settings.dispose();
    subscription.dispose();
  });

  Future<void> shoot(WidgetTester tester, String name, Widget screen) async {
    // The device exactly: 1290 physical pixels across at a ratio of 3, so
    // the layout is the 430 points a 6.7" phone actually has. Faking the
    // ratio as 1 lays out the same but resolves every asset at 1.0x, and
    // the illustrations would be upscaled in the store's own images.
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
            home: screen,
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
      'build/screenshots/$name.png',
      pixelRatio: _ratio,
    );
  }

  testWidgets('1 — the scenario list', (tester) async {
    await shoot(tester, '01-home', const TabsScreen());
  });

  testWidgets('2 — the briefing', (tester) async {
    await shoot(tester, '02-brief', BriefScreen(scenario: _scenario));
  });

  testWidgets('3 — mid-conversation', (tester) async {
    await shoot(
      tester,
      '03-practice',
      PracticeScreen(
        scenario: _scenario,
        mode: PracticeMode.freestyle,
        difficulty: SimulationDifficulty.defensive,
        coachService: OfflineCoachService(),
      ),
    );
  });

  testWidgets('4 — the coaching report', (tester) async {
    await shoot(
      tester,
      '04-report',
      ResultsScreen(
        scenario: _scenario,
        mode: PracticeMode.freestyle,
        summary: _report(),
      ),
    );
  });

  testWidgets('5 — progress', (tester) async {
    // Through the shell, so the store sees the bar the app actually has.
    await shoot(tester, '05-progress', const TabsScreen(initialTab: 1));
  });

  testWidgets('6 — the intro', (tester) async {
    await shoot(tester, '06-onboarding', const OnboardingScreen());
  });
}

/// A believable report: good on empathy, soft on the expectation. The same
/// shape the demo script uses.
PracticeSummary _report() {
  return parseEvaluation({
    'overall_score': 71,
    'clarity': 64,
    'empathy': 88,
    'directness': 58,
    'confidence': 66,
    'summary':
        'You made real room for the pressure Jordan is under, then let the '
        'deadline dissolve into a promise to keep talking.',
    'strengths': [
      {
        'turn_index': 0,
        'quote': 'I see how much you have taken on',
        'comment':
            'Naming the load before the problem is why Jordan kept talking '
            'instead of defending.',
        'suggestion': '',
      },
    ],
    'improvements': [
      {
        'turn_index': 2,
        'quote': 'just keep me posted',
        'comment':
            '"Posted" has no date and no threshold, so Jordan can meet it by '
            'saying nothing.',
        'suggestion':
            'If Friday is at risk, I need to know by Wednesday — not on the '
            'day.',
      },
    ],
  }, history: _transcript);
}

final _transcript = [
  PracticeResponse.spoken(
    text:
        'I see how much you have taken on. We still need to talk about the '
        'two missed handoffs.',
    employeeReply: 'The scope keeps moving though.',
    source: EvaluationSource.ai,
  ),
  PracticeResponse.spoken(
    text: 'What part of the changing scope is creating the biggest risk?',
    employeeReply: 'Design review lands after engineering has started.',
    source: EvaluationSource.ai,
  ),
  PracticeResponse.spoken(
    text: 'Okay. Do what you can and just keep me posted.',
    employeeReply: 'Sure, I will.',
    source: EvaluationSource.ai,
  ),
];
