import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/app.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/screens/home_screen.dart';
import 'package:rehearse/screens/onboarding_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/practice_history.dart';
import 'package:rehearse/services/subscription.dart';

void main() {
  Future<(AppSettings, _Sink)> pumpApp(
    WidgetTester tester, {
    bool seenBefore = false,
    SettingsStore? store,
  }) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settings = AppSettings(
      store:
          store ??
          InMemorySettingsStore(
            seenBefore ? {'rehearse.onboarding_completed': true} : null,
          ),
    );
    addTearDown(settings.dispose);
    final history = PracticeHistory(store: InMemoryHistoryStore());
    addTearDown(history.dispose);
    final subscription = Subscription(store: InMemorySettingsStore());
    addTearDown(subscription.dispose);
    final sink = _Sink();
    final analytics = Analytics(sink: sink);
    addTearDown(analytics.dispose);

    await tester.pumpWidget(
      RehearseApp(
        history: history,
        settings: settings,
        subscription: subscription,
        analytics: analytics,
      ),
    );
    await tester.pumpAndSettle();
    return (settings, sink);
  }

  group('first run', () {
    testWidgets('opens on the intro, not the scenario list', (tester) async {
      final (_, sink) = await pumpApp(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(
        find.text('Practice the conversation before it matters.'),
        findsOneWidget,
      );
      expect(sink.names, contains('onboarding_started'));
    });

    testWidgets('walks three pages and ends on the promised CTA', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Next'), findsOneWidget);
      expect(find.byKey(const Key('skip_onboarding')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('They won’t always agree with you.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('See exactly what to improve.'), findsOneWidget);

      // The last page commits rather than offering an escape.
      expect(find.text('Start practicing'), findsOneWidget);
      expect(find.byKey(const Key('skip_onboarding')), findsNothing);
    });

    testWidgets('finishing lands on home and is remembered', (tester) async {
      final store = InMemorySettingsStore();
      final (settings, sink) = await pumpApp(tester, store: store);

      for (var page = 0; page < 2; page++) {
        await tester.tap(find.byKey(const Key('onboarding_next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(settings.onboardingCompleted, isTrue);
      expect(await store.readBool('rehearse.onboarding_completed'), isTrue);

      final completed = sink.eventNamed('onboarding_completed');
      expect(completed['pages_seen'], 3);
      expect(completed['skipped'], isFalse);
    });

    testWidgets('skipping also counts as done, and says so', (tester) async {
      final (settings, sink) = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('skip_onboarding')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(settings.onboardingCompleted, isTrue);

      final completed = sink.eventNamed('onboarding_completed');
      expect(completed['skipped'], isTrue);
      expect(completed['pages_seen'], 1);
    });
  });

  group('returning', () {
    testWidgets('goes straight to the scenario list', (tester) async {
      final (_, sink) = await pumpApp(tester, seenBefore: true);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(sink.names, isNot(contains('onboarding_started')));
    });

    testWidgets('can ask for the intro again from the You tab', (tester) async {
      final (settings, _) = await pumpApp(tester, seenBefore: true);
      expect(find.byType(OnboardingScreen), findsNothing);

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('replay_intro')));
      await tester.pumpAndSettle();

      // Nothing navigates: the root watches the flag and swaps itself.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(settings.onboardingCompleted, isFalse);

      await tester.tap(find.byKey(const Key('skip_onboarding')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('never flashes the intro while preferences load', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settings = AppSettings(
        store: _SlowStore({'rehearse.onboarding_completed': true}),
      );
      addTearDown(settings.dispose);
      final history = PracticeHistory(store: InMemoryHistoryStore());
      addTearDown(history.dispose);
      final subscription = Subscription(store: InMemorySettingsStore());
      addTearDown(subscription.dispose);

      await tester.pumpWidget(
        RehearseApp(
          history: history,
          settings: settings,
          subscription: subscription,
        ),
      );

      // While the read is outstanding the app shows its launch state, never
      // an intro it will have to take back.
      await tester.pump();
      expect(find.byKey(const Key('launch')), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('honesty', () {
    testWidgets('names every dimension the report actually scores', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();

      // The promise and the rubric have to move together, in both
      // directions: naming one the report lacks oversells, and omitting one
      // it has undersells.
      final promise = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase();

      for (final skill in PracticeSkill.values) {
        expect(
          promise,
          contains(skill.label.toLowerCase()),
          reason:
              'the report scores ${skill.label} but the intro never says so',
        );
      }
    });

    testWidgets('promises the resistance choice, now that there is one', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();

      expect(find.text('They won’t always agree with you.'), findsOneWidget);
      expect(find.textContaining('how hard they push back'), findsOneWidget);
    });
  });
}

class _Sink implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  List<String> get names => [for (final event in events) event.$1];

  Map<String, Object> eventNamed(String name) =>
      events.firstWhere((event) => event.$1 == name).$2;

  @override
  Future<bool> configure() async => true;

  @override
  Future<void> track(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> setSuperProperties(Map<String, Object> properties) async {}
}

/// Defers its answer by a frame, standing in for a cold start where the
/// platform channel has not replied yet.
class _SlowStore implements SettingsStore {
  _SlowStore(this._values);

  final Map<String, Object> _values;

  @override
  Future<bool?> readBool(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final value = _values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<int?> readInt(String key) async => null;

  @override
  Future<void> writeInt(String key, int value) async {}

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> writeString(String key, String value) async {}
}
