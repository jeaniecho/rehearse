import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/app.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/services/speech_input_service.dart';
import 'package:rehearse/theme/app_theme.dart';

void main() {
  testWidgets('completes the recommended practice and shows coaching', (
    tester,
  ) async {
    final history = PracticeHistory(store: InMemoryHistoryStore());
    addTearDown(history.dispose);
    final subscription = Subscription(store: InMemorySettingsStore());
    addTearDown(subscription.dispose);
    final settings = AppSettings(store: seenOnboarding());
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      RehearseApp(
        history: history,
        subscription: subscription,
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Say the hard thing.\nBetter.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start_recommended')));
    await tester.pumpAndSettle();

    expect(find.text('Scenario briefing'), findsOneWidget);
    expect(find.text('Jordan Lee'), findsOneWidget);

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

    await tester.tap(find.byKey(const Key('choice_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coach_feedback')), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choice_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choice_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue_practice')));
    await tester.pumpAndSettle();

    expect(find.text('COACHING REPORT'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('You held the line with care.'), findsOneWidget);

    expect(history.records, hasLength(1));
    expect(history.records.single.scenarioId, scenarios.first.id);
    expect(history.records.single.score, 88);
    expect(history.records.single.mode, PracticeMode.guided);

    // Nothing is configured in a test build, so the loop stays unmetered.
    expect(subscription.isConfigured, isFalse);
    expect(subscription.freeSessionsUsed, 0);
    expect(subscription.canStartPractice, isTrue);
  });

  testWidgets('a free-form turn is answered, not marked', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PracticeScreen(
          scenario: scenarios.first,
          mode: PracticeMode.freestyle,
          coachService: OfflineCoachService(),
        ),
      ),
    );

    const said =
        'I see how much you have taken on. We still need to discuss the '
        'missed handoffs and agree on a next step.';
    await tester.enterText(find.byKey(const Key('freeform_response')), said);
    await tester.tap(find.byKey(const Key('submit_response')));
    await tester.pumpAndSettle();

    // The reply is the consequence. Nothing narrates the manager's technique
    // mid-conversation (PRD §7.3).
    expect(find.text(said), findsOneWidget);
    expect(find.byKey(const Key('coach_feedback')), findsNothing);
    expect(find.byKey(const Key('continue_practice')), findsNothing);
    expect(find.text(scenarios.first.turns[1].employeeLine), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('a free-form conversation ends in a coaching report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PracticeScreen(
          scenario: scenarios.first,
          mode: PracticeMode.freestyle,
          coachService: OfflineCoachService(),
        ),
      ),
    );

    for (var turn = 0; turn < scenarios.first.turns.length; turn++) {
      await tester.enterText(
        find.byKey(const Key('freeform_response')),
        'I need the handoff by Friday. Which task moves to make room for it?',
      );
      await tester.tap(find.byKey(const Key('submit_response')));
      await tester.pumpAndSettle();
    }

    expect(find.text('COACHING REPORT'), findsOneWidget);
    expect(find.text('Private demo scoring'), findsOneWidget);
  });

  testWidgets('adds live speech after existing typed text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final speech = FakeSpeechInputService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PracticeScreen(
          scenario: scenarios.first,
          mode: PracticeMode.freestyle,
          coachService: OfflineCoachService(),
          speechInputService: speech,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('freeform_response')),
      'Jordan,',
    );
    await tester.tap(find.byKey(const Key('speech_input')));
    await tester.pump();

    expect(
      find.text('Listening… speak naturally, then tap stop.'),
      findsOneWidget,
    );
    expect(speech.startCalls, 1);

    speech.emit('I hear how much you have taken on.');
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('freeform_response')),
    );
    expect(
      field.controller!.text,
      'Jordan, I hear how much you have taken on.',
    );

    await tester.tap(find.byKey(const Key('speech_input')));
    await tester.pump();
    expect(speech.stopCalls, 1);
  });

  testWidgets('keeps typing available when speech is unsupported', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PracticeScreen(
          scenario: scenarios.first,
          mode: PracticeMode.freestyle,
          coachService: OfflineCoachService(),
          speechInputService: FakeSpeechInputService(available: false),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('speech_input')));
    await tester.pump();

    expect(
      find.text(
        'Speech input isn’t available here. You can still type your response.',
      ),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(
      find.byKey(const Key('freeform_response')),
    );
    expect(field.enabled, isTrue);
    expect(field.readOnly, isFalse);
  });

  testWidgets('response panel fills and owns the bottom safe area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: PracticeScreen(
            scenario: scenarios.first,
            mode: PracticeMode.freestyle,
            coachService: OfflineCoachService(),
            speechInputService: FakeSpeechInputService(),
          ),
        ),
      ),
    );

    final panel = find.byKey(const Key('response_panel'));
    expect(panel, findsOneWidget);
    expect(tester.getBottomLeft(panel).dy, 844);
  });
}

/// A settings store for a returning manager, so tests start on the home
/// screen rather than the intro.
InMemorySettingsStore seenOnboarding() =>
    InMemorySettingsStore({'rehearse.onboarding_completed': true});

class FakeSpeechInputService implements SpeechInputService {
  FakeSpeechInputService({this.available = true});

  final bool available;
  SpeechStateCallback? _onListeningChanged;
  SpeechResultCallback? _onResult;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<bool> initialize({
    required SpeechStateCallback onListeningChanged,
    required SpeechErrorCallback onError,
  }) async {
    _onListeningChanged = onListeningChanged;
    return available;
  }

  @override
  Future<void> start({required SpeechResultCallback onResult}) async {
    startCalls += 1;
    _onResult = onResult;
    _onListeningChanged?.call(true);
  }

  void emit(String text, {bool isFinal = false}) {
    _onResult?.call(text, isFinal);
    if (isFinal) _onListeningChanged?.call(false);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _onListeningChanged?.call(false);
  }

  @override
  Future<void> cancel() async {}
}
