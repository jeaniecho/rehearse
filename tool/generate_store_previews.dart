// Renders the App Store / Play *preview* images — the ones with a headline
// on them, as opposed to the bare screens `generate_screenshots.dart` makes.
//
//   flutter test tool/generate_store_previews.dart
//
// Output lands in build/store-previews/.
//
// The screen inside each frame is the real app with seeded data, not a
// mockup, for the same reason the plain screenshots are: marketing that is
// drawn separately from the product drifts from it, and nobody notices until
// a reviewer does. Everything else on the canvas — the ground, the ink, the
// shadow, the two typefaces — comes from `AppColors` and `Paper`, so the
// store images cannot drift from the brand either.
//
// Captions live in `docs/RELEASE.md` §4 alongside the rest of the store copy.
// Apple shows the first two or three in search results, so their order is a
// decision, not a sequence: the hook, then what makes it different, then the
// payoff.
import 'dart:io';

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

/// 6.7" iPhone — the size App Store Connect requires. Play accepts it too.
const _size = Size(1290, 2796);
const _ratio = 3.0;

/// The logical canvas the caption and the frame are laid out on.
const _canvas = Size(430, 932);

/// The phone sits below its headline, scaled down and bleeding off the
/// bottom edge: the screen is evidence, not the subject, and cropping it
/// says "there is more" without spending height saying so.
const _phoneScale = 0.82;
const _phoneTop = 210.0;

final _scenario = scenarios.firstWhere((s) => s.id == 'missed-deadlines');

late HarnessFonts _fonts;

/// Forest for the two images that carry an argument, ground for the rest.
/// One dark frame in a row of light ones is a rhythm; three is a theme
/// nobody asked for.
enum _Tone {
  // `subtle` rather than `ground`: the app's own canvas IS ground, so a
  // ground canvas made the phone invisible — same colour behind and in
  // front, with a rounded corner and a shadow doing nothing between them.
  light(AppColors.subtle, AppColors.ink, AppColors.muted),
  dark(AppColors.forest, Colors.white, AppColors.onForestMuted);

  const _Tone(this.background, this.ink, this.muted);

  final Color background;
  final Color ink;
  final Color muted;
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
    await Directory('build/store-previews').create(recursive: true);
  });

  setUp(() async {
    history = PracticeHistory(store: InMemoryHistoryStore());
    settings = AppSettings(
      store: InMemorySettingsStore({'rehearse.onboarding_completed': true}),
    );
    subscription = Subscription();
    await settings.load();
    await subscription.load();

    // Momentum rather than a first run. An empty app sells nothing.
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
    sizeAsDevice(tester, _size, _ratio);
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: _canvas.width,
            height: _canvas.height,
            color: tone.background,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 74, 34, 0),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        caption,
                        style: TextStyle(
                          // Outside the inner MaterialApp, so it inherits no
                          // theme: without the family named here every glyph
                          // in the headline renders as a box.
                          fontFamily: AppTheme.fontFamily,
                          color: tone.ink,
                          fontSize: 34,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                // The phone. Scaled about its top edge so the crop happens
                // at the bottom of the canvas rather than around the middle
                // of the screen it is showing.
                Positioned(
                  top: _phoneTop,
                  left: 0,
                  right: 0,
                  child: Align(
                    child: Transform.scale(
                      scale: _phoneScale,
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: _canvas.width,
                        height: _canvas.height,
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
                            width: _canvas.width,
                            height: _canvas.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
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
                                // The harness reserves 59pt of top padding,
                                // so every screen already lays out below this
                                // band — it was just empty. A phone with no
                                // status bar reads as a mockup of a phone.
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

    // A preview has to show the thing its headline promises. The report's
    // quote is below the fold on a phone, so the screen is scrolled to it
    // rather than the caption being softened to match what happened to be
    // visible.
    if (scrollBy != 0) {
      await tester.drag(find.byType(Scrollable).first, Offset(0, -scrollBy));
      await tester.pumpAndSettle();
    }

    await writePng(
      tester,
      boundary,
      'build/store-previews/$name.png',
      pixelRatio: _ratio,
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
}

/// A report worth photographing: a real critique with a quote and a rewrite.
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
