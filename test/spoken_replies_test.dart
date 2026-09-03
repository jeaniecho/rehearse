import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/services/speech_input_service.dart';
import 'package:rehearse/services/speech_output_service.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/app_settings_scope.dart';

void main() {
  final scenario = scenarios.first;

  Future<(FakeSpeechOutputService, AppSettings)> pumpPractice(
    WidgetTester tester, {
    bool voiceAvailable = true,
    bool spokenRepliesEnabled = true,
    SpeechInputService? input,
  }) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final voice = FakeSpeechOutputService(available: voiceAvailable);
    final settings = AppSettings(
      store: InMemorySettingsStore({
        'rehearse.spoken_replies': spokenRepliesEnabled,
      }),
    );
    addTearDown(settings.dispose);
    await settings.load();

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          theme: AppTheme.light,
          home: PracticeScreen(
            scenario: scenario,
            mode: PracticeMode.freestyle,
            coachService: OfflineCoachService(),
            speechInputService: input ?? FakeSpeechInputService(),
            speechOutputService: voice,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (voice, settings);
  }

  testWidgets('reads the opening line aloud', (tester) async {
    final (voice, _) = await pumpPractice(tester);

    expect(voice.spoken, [scenario.turns.first.employeeLine]);
    expect(find.byKey(const Key('toggle_voice')), findsOneWidget);
  });

  testWidgets('shows who is talking while a line plays', (tester) async {
    final (voice, _) = await pumpPractice(tester);

    expect(find.byKey(const Key('speaking_indicator')), findsNothing);

    voice.startSpeaking();
    await tester.pump();
    expect(find.byKey(const Key('speaking_indicator')), findsOneWidget);

    voice.finishSpeaking();
    await tester.pump();
    expect(find.byKey(const Key('speaking_indicator')), findsNothing);
  });

  testWidgets('stays silent when the manager has muted the character', (
    tester,
  ) async {
    final (voice, _) = await pumpPractice(tester, spokenRepliesEnabled: false);

    expect(voice.spoken, isEmpty);
    expect(find.byKey(const Key('replay_line')), findsNothing);
  });

  testWidgets('the mute toggle takes effect and is remembered', (tester) async {
    final (voice, settings) = await pumpPractice(tester);
    expect(voice.spoken, hasLength(1));

    await tester.tap(find.byKey(const Key('toggle_voice')));
    await tester.pumpAndSettle();

    expect(settings.spokenRepliesEnabled, isFalse);
    expect(voice.stopCalls, 1);

    await tester.tap(find.byKey(const Key('toggle_voice')));
    await tester.pumpAndSettle();

    expect(settings.spokenRepliesEnabled, isTrue);
    expect(voice.spoken, hasLength(2));
  });

  testWidgets('hides the toggle when the device has no voice', (tester) async {
    final (voice, _) = await pumpPractice(tester, voiceAvailable: false);

    expect(voice.spoken, isEmpty);
    expect(find.byKey(const Key('toggle_voice')), findsNothing);
    expect(find.byKey(const Key('replay_line')), findsNothing);
    // Practice itself is unaffected.
    expect(find.byKey(const Key('freeform_response')), findsOneWidget);
  });

  testWidgets('reads the next line once the turn advances', (tester) async {
    final (voice, _) = await pumpPractice(tester);

    await tester.enterText(
      find.byKey(const Key('freeform_response')),
      'I hear you. We still need the handoffs on time — can we agree on that?',
    );
    await tester.tap(find.byKey(const Key('submit_response')));
    await tester.pumpAndSettle();

    // Sending advances the turn on its own now; the new line is spoken.
    expect(voice.spoken, hasLength(2));
    expect(voice.spoken.last, isNot(voice.spoken.first));
  });

  testWidgets('tapping the bubble replays, then cuts the line short', (
    tester,
  ) async {
    final (voice, _) = await pumpPractice(tester);

    await tester.tap(find.byKey(const Key('replay_line')));
    await tester.pumpAndSettle();
    expect(voice.spoken, hasLength(2));

    voice.startSpeaking();
    await tester.pump();
    await tester.tap(find.byKey(const Key('replay_line')));
    await tester.pumpAndSettle();

    expect(voice.stopCalls, 1);
    expect(voice.spoken, hasLength(2));
  });

  testWidgets('goes quiet as soon as the microphone opens', (tester) async {
    final input = FakeSpeechInputService();
    final (voice, _) = await pumpPractice(tester, input: input);

    await tester.tap(find.byKey(const Key('speech_input')));
    await tester.pumpAndSettle();

    expect(voice.stopCalls, 1);
    expect(input.startCalls, 1);
  });

  group('AppSettings', () {
    test('defaults to spoken replies on', () async {
      final settings = AppSettings(store: InMemorySettingsStore());
      addTearDown(settings.dispose);

      await settings.load();
      expect(settings.spokenRepliesEnabled, isTrue);
    });

    test('persists a change and reloads it', () async {
      final store = InMemorySettingsStore();
      final settings = AppSettings(store: store);
      addTearDown(settings.dispose);
      var notifications = 0;
      settings.addListener(() => notifications += 1);

      await settings.setSpokenRepliesEnabled(false);
      expect(notifications, 1);

      // Setting the same value again is not a change.
      await settings.setSpokenRepliesEnabled(false);
      expect(notifications, 1);

      final reloaded = AppSettings(store: store);
      addTearDown(reloaded.dispose);
      await reloaded.load();
      expect(reloaded.spokenRepliesEnabled, isFalse);
    });

    test('an unreadable store leaves the default in place', () async {
      final settings = AppSettings(store: _BrokenSettingsStore());
      addTearDown(settings.dispose);

      await settings.load();
      expect(settings.spokenRepliesEnabled, isTrue);

      await settings.setSpokenRepliesEnabled(false);
      expect(settings.spokenRepliesEnabled, isFalse);
    });
  });
}

class FakeSpeechOutputService implements SpeechOutputService {
  FakeSpeechOutputService({this.available = true});

  final bool available;
  final List<String> spoken = [];
  int stopCalls = 0;
  SpeakingStateCallback? _onSpeakingChanged;

  @override
  Future<bool> initialize({
    required SpeakingStateCallback onSpeakingChanged,
  }) async {
    _onSpeakingChanged = onSpeakingChanged;
    return available;
  }

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _onSpeakingChanged?.call(false);
  }

  void startSpeaking() => _onSpeakingChanged?.call(true);

  void finishSpeaking() => _onSpeakingChanged?.call(false);
}

class FakeSpeechInputService implements SpeechInputService {
  int startCalls = 0;
  SpeechStateCallback? _onListeningChanged;

  @override
  Future<bool> initialize({
    required SpeechStateCallback onListeningChanged,
    required SpeechErrorCallback onError,
  }) async {
    _onListeningChanged = onListeningChanged;
    return true;
  }

  @override
  Future<void> start({required SpeechResultCallback onResult}) async {
    startCalls += 1;
    _onListeningChanged?.call(true);
  }

  @override
  Future<void> stop() async => _onListeningChanged?.call(false);

  @override
  Future<void> cancel() async {}
}

class _BrokenSettingsStore implements SettingsStore {
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

  @override
  Future<String?> readString(String key) async =>
      throw StateError('unavailable');

  @override
  Future<void> writeString(String key, String value) async =>
      throw StateError('unavailable');
}
