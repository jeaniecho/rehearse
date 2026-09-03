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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/onboarding_screen.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/progress_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/analytics_scope.dart';
import 'package:rehearse/widgets/app_settings_scope.dart';
import 'package:rehearse/widgets/practice_history_scope.dart';
import 'package:rehearse/widgets/subscription_scope.dart';

/// 6.7" iPhone — the size App Store Connect requires. Play accepts it too.
const _size = Size(1290, 2796);
const _ratio = 3.0;

final _scenario = scenarios.first;

/// The theme asks for 'SF Pro Display', which the test environment does not
/// have — without this every glyph renders as a box and the output is
/// useless as a store asset.
///
/// Loading the system copy works on a Mac and produces exactly what an
/// iPhone shows. Elsewhere the generator still runs and still checks layout;
/// it just cannot be used for submission.
Future<bool> _loadBrandFont() async {
  final text = await _register('SF Pro Display', const [
    '/System/Library/Fonts/SFNS.ttf',
    '/System/Library/Fonts/Helvetica.ttc',
  ]);

  // Icons live in a separate family the test environment does not load
  // either, so without this every icon renders as a box too.
  final root = Platform.environment['FLUTTER_ROOT'];
  final home = Platform.environment['HOME'];
  const suffix = 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  await _register('MaterialIcons', [
    if (root != null && root.isNotEmpty) '$root/$suffix',
    if (home != null) '$home/Dev/flutter/$suffix',
    if (home != null) '$home/flutter/$suffix',
  ]);

  return text;
}

Future<bool> _register(String family, List<String> candidates) async {
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    try {
      final bytes = await file.readAsBytes();
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return true;
    } on Object {
      continue;
    }
  }
  return false;
}

void main() {
  late PracticeHistory history;
  late AppSettings settings;
  late Subscription subscription;

  setUpAll(() async {
    if (!await _loadBrandFont()) {
      stdout.writeln(
        'WARNING: no system font found — glyphs will render as boxes and '
        'these images must not be submitted.',
      );
    }
  });

  setUp(() async {
    history = PracticeHistory(store: InMemoryHistoryStore());
    settings = AppSettings(
      store: InMemorySettingsStore({'rehearse.onboarding_completed': true}),
    );
    subscription = Subscription(store: InMemorySettingsStore());
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
    // Lay out at the logical size a 6.7" phone actually has, then rasterise
    // at its pixel ratio. Laying out at 1290 points wide instead would give
    // a tablet layout at the right resolution, which is not the same thing.
    tester.view.physicalSize = Size(
      _size.width / _ratio,
      _size.height / _ratio,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: PracticeHistoryScope(
          history: history,
          child: AppSettingsScope(
            settings: settings,
            child: SubscriptionScope(
              subscription: subscription,
              child: AnalyticsScope(
                analytics: Analytics(sink: const NoopAnalyticsSink()),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  home: screen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: _ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      stdout.writeln('wrote ${file.path}  ${image.width}x${image.height}');
      image.dispose();
    });
  }

  testWidgets('1 — the scenario list', (tester) async {
    await shoot(tester, '01-home', const HomeScreen());
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
    await shoot(tester, '05-progress', const ProgressScreen());
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
