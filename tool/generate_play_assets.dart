// Renders the Play Store assets: phone screenshots and the feature graphic.
//
//   flutter test tool/generate_play_assets.dart
//
// Output lands in build/play/.
//
// Play will not take the App Store images. Its phone screenshots must be
// between 16:9 and 9:16, and a 6.7" iPhone is 9:19.5 — taller than the
// allowed range, so `generate_store_previews.dart`'s output is rejected
// rather than merely letterboxed. These are 1080×1920, which is exactly 9:16.
//
// The feature graphic is 1024×500 with no alpha, and Play crops it on some
// surfaces and lays a play button over it on others, so nothing that has to
// be read goes near an edge or dead centre.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/coaching_note.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/models/session_outcome.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/screens/tabs_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/theme/paper.dart';
import 'package:rehearse/widgets/illustration.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

import 'harness.dart';

/// 1080×1920 — 9:16 exactly, the tallest Play allows.
const _shotSize = Size(1080, 1920);
const _shotRatio = 3.0;
const _shotCanvas = Size(360, 640);

/// The device the app is actually laid out for, scaled into the frame above.
/// Laying the app out at 360×640 instead would be photographing a phone
/// nobody owns.
const _deviceCanvas = Size(430, 932);

/// 1024×500, Play's fixed feature graphic. Rendered at 1 rather than 3: this
/// is the delivered size, not a logical one.
const _featureSize = Size(1024, 500);

final _scenario = scenarios.firstWhere((s) => s.id == 'missed-deadlines');

late HarnessFonts _fonts;

enum _Tone {
  light(AppColors.subtle, AppColors.ink),
  dark(AppColors.forest, Colors.white);

  const _Tone(this.background, this.ink);

  final Color background;
  final Color ink;
}

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
    await Directory('build/play').create(recursive: true);
  });

  setUp(() async {
    history = PracticeHistory(store: InMemoryHistoryStore());
    settings = AppSettings(
      store: InMemorySettingsStore({'rehearse.onboarding_completed': true}),
    );
    subscription = Subscription();
    await settings.load();
    await subscription.load();

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

  Future<void> shoot(
    WidgetTester tester,
    String name,
    String caption,
    Widget screen, {
    _Tone tone = _Tone.light,
    String? kicker,
    double scrollBy = 0,
  }) async {
    sizeAsDevice(tester, _shotSize, _shotRatio);
    addTearDown(tester.view.reset);

    // The frame is 360 wide; the app is 430. Scaling by the ratio of the two
    // keeps the phone proportionate to the canvas at any frame size.
    const scale = 0.66;

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: _shotCanvas.width,
            height: _shotCanvas.height,
            color: tone.background,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 44, 26, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kicker != null) ...[
                        Text(
                          kicker.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: tone == _Tone.dark
                                ? AppColors.mint
                                : AppColors.coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      Text(
                        caption,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: tone.ink,
                          fontSize: 25,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 148,
                  left: 0,
                  right: 0,
                  child: Align(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: _deviceCanvas.width,
                        height: _deviceCanvas.height,
                        decoration: BoxDecoration(
                          color: AppColors.ground,
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                          boxShadow: Paper.float,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(38),
                          child: SizedBox(
                            width: _deviceCanvas.width,
                            height: _deviceCanvas.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: MediaQuery(
                                    // The app laid out for the phone it is written
                                    // for, not for the frame it is photographed in.
                                    data: const MediaQueryData(
                                      size: _deviceCanvas,
                                      devicePixelRatio: 3,
                                      // 59 at the top, which is the band
                                      // `StoreStatusBar` fills — the screens lay
                                      // out below it either way.
                                      padding: EdgeInsets.only(
                                        top: 59,
                                        bottom: 34,
                                      ),
                                    ),
                                    child: RehearseScope(
                                      history: history,
                                      settings: settings,
                                      subscription: subscription,
                                      analytics: Analytics(
                                        sink: const NoopAnalyticsSink(),
                                      ),
                                      child: MaterialApp(
                                        debugShowCheckedModeBanner: false,
                                        theme: _fonts.theme,
                                        home: screen,
                                      ),
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: StoreStatusBar(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(
      () => Illustration.precacheAll(tester.element(find.byType(MaterialApp))),
    );
    await tester.pumpAndSettle();

    if (scrollBy != 0) {
      await tester.drag(find.byType(Scrollable).first, Offset(0, -scrollBy));
      await tester.pumpAndSettle();
    }

    await writePng(
      tester,
      boundary,
      'build/play/$name.png',
      pixelRatio: _shotRatio,
    );
  }

  testWidgets('1 — the hook', (tester) async {
    await shoot(
      tester,
      '01-rehearse-it-first',
      'You’ll have it once.\nRehearse it first.',
      const TabsScreen(),
      kicker: 'Before the real thing',
    );
  });

  testWidgets('2 — they push back', (tester) async {
    await shoot(
      tester,
      '02-they-push-back',
      'They answer what\nyou actually said.',
      PracticeScreen(
        scenario: _scenario,
        mode: PracticeMode.freestyle,
        difficulty: SimulationDifficulty.defensive,
        coachService: OfflineCoachService(),
      ),
      tone: _Tone.dark,
      kicker: 'Calm, defensive, very defensive',
    );
  });

  testWidgets('3 — the sentence that cost you', (tester) async {
    await shoot(
      tester,
      '03-the-sentence',
      'See the sentence\nthat cost you.',
      ResultsScreen(
        scenario: _scenario,
        mode: PracticeMode.freestyle,
        summary: _report(),
      ),
      kicker: 'Quoted back, in your own words',
      scrollBy: 300,
    );
  });

  testWidgets('4 — the briefing', (tester) async {
    await shoot(
      tester,
      '04-know-the-goal',
      'Know the goal\nbefore you walk in.',
      BriefScreen(scenario: _scenario),
      kicker: 'The trap most people fall into',
    );
  });

  testWidgets('5 — progress', (tester) async {
    await shoot(
      tester,
      '05-watch-it-build',
      'Watch the habit\nbuild.',
      const TabsScreen(initialTab: 1),
      tone: _Tone.dark,
      kicker: 'Clarity · empathy · directness · confidence',
    );
  });

  testWidgets('feature graphic', (tester) async {
    tester.view.physicalSize = _featureSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The mark itself, from the master rather than the bundled variants —
    // those top out at 156px and this draws it at more than twice that.
    late final ui.Image mark;
    await tester.runAsync(() async {
      final bytes = await File('art/illustrations/logo.png').readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 420);
      mark = (await codec.getNextFrame()).image;
    });

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: _featureSize.width,
            height: _featureSize.height,
            // Opaque: Play rejects a feature graphic with an alpha channel.
            color: AppColors.forest,
            child: Stack(
              children: [
                // The mark sits right, where Play's own play button overlays
                // on the surfaces that have one — so it is the thing covered,
                // not a word.
                Positioned(
                  right: -40,
                  top: 40,
                  child: SizedBox(
                    width: 420,
                    height: 420,
                    child: RawImage(image: mark, fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  // Play crops this on some surfaces, so the words live left of
                  // centre and well inside the edges.
                  padding: const EdgeInsets.fromLTRB(72, 0, 380, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REHEARSE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.mint,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'You’ll have it once.\nRehearse it first.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.white,
                          fontSize: 46,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Practice the conversations you keep putting off.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.onForestMuted,
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await writePng(
      tester,
      boundary,
      'build/play/feature-graphic.png',
      pixelRatio: 1,
    );
  });
}

PracticeSummary _report() => PracticeSummary.fromEvaluation(
  score: 74,
  outcome: SessionOutcome.partial,
  skills: const {
    PracticeSkill.clarity: 80,
    PracticeSkill.empathy: 66,
    PracticeSkill.directness: 78,
    PracticeSkill.confidence: 72,
  },
  summary:
      'You named the pattern early, then let the deadline slide into a '
      'promise to keep talking.',
  strengths: const [
    CoachingNote(
      turnIndex: 0,
      quote: 'This is the second handoff we have missed',
      comment: 'Named the pattern instead of the incident.',
    ),
  ],
  improvements: const [
    CoachingNote(
      turnIndex: 2,
      quote: 'just keep me posted',
      comment: '“Posted” has no date and no threshold.',
      suggestion: 'Send me the revised date by Thursday.',
    ),
  ],
  usedAi: true,
);
