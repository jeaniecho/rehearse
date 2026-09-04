import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/screens/brief_screen.dart';
import 'package:rehearse/screens/you_screen.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/services/analytics.dart';
import 'package:rehearse/services/analytics_sink.dart';
import 'package:rehearse/services/app_settings.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/analytics_scope.dart';
import 'package:rehearse/widgets/app_settings_scope.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

final scenario = scenarios.first;

void main() {
  /// The picker sits below the fold behind the fixed action bar, so a tap
  /// has to scroll to it the way a person would.
  Future<void> pick(WidgetTester tester, SimulationDifficulty level) async {
    final target = find.byKey(Key('difficulty_${level.name}'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<(AppSettings, _Sink)> pumpBrief(
    WidgetTester tester, {
    SettingsStore? store,
  }) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settings = AppSettings(store: store ?? InMemorySettingsStore());
    addTearDown(settings.dispose);
    await settings.load();
    final sink = _Sink();
    final analytics = Analytics(sink: sink);
    addTearDown(analytics.dispose);

    await tester.pumpWidget(
      AppSettingsScope(
        settings: settings,
        child: AnalyticsScope(
          analytics: analytics,
          child: MaterialApp(
            theme: AppTheme.light,
            home: BriefScreen(scenario: scenario),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (settings, sink);
  }

  group('choosing', () {
    testWidgets('offers three levels and starts on the realistic middle', (
      tester,
    ) async {
      await pumpBrief(tester);

      for (final level in SimulationDifficulty.values) {
        expect(
          find.byKey(Key('difficulty_${level.name}')),
          findsOneWidget,
          reason: level.name,
        );
      }
      expect(
        find.text(SimulationDifficulty.defensive.description),
        findsOneWidget,
      );
    });

    testWidgets('picking a level explains what it means', (tester) async {
      final (settings, sink) = await pumpBrief(tester);

      await pick(tester, SimulationDifficulty.veryDefensive);

      expect(settings.difficulty, SimulationDifficulty.veryDefensive);
      expect(
        find.text(SimulationDifficulty.veryDefensive.description),
        findsOneWidget,
      );
      expect(
        sink.eventNamed('difficulty_selected')['difficulty'],
        'veryDefensive',
      );
    });

    testWidgets('re-picking the current level is not a change', (tester) async {
      final (_, sink) = await pumpBrief(tester);

      await pick(tester, SimulationDifficulty.defensive);

      expect(sink.names, isNot(contains('difficulty_selected')));
    });

    testWidgets('the choice is remembered', (tester) async {
      final store = InMemorySettingsStore();
      await pumpBrief(tester, store: store);

      await pick(tester, SimulationDifficulty.calm);

      final reloaded = AppSettings(store: store);
      addTearDown(reloaded.dispose);
      await reloaded.load();
      expect(reloaded.difficulty, SimulationDifficulty.calm);
    });

    testWidgets('the You tab sets the level a briefing opens on', (
      tester,
    ) async {
      final store = InMemorySettingsStore();
      final settings = AppSettings(store: store);
      addTearDown(settings.dispose);
      await settings.load();

      await tester.pumpWidget(
        RehearseScope(
          settings: settings,
          child: MaterialApp(theme: AppTheme.light, home: const YouScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final target = find.byKey(const Key('default_difficulty_veryDefensive'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(settings.difficulty, SimulationDifficulty.veryDefensive);

      // The briefing opens on it rather than on the default, which is the
      // whole point of the setting being remembered.
      await pumpBrief(tester, store: store);
      expect(
        find.text(SimulationDifficulty.veryDefensive.description),
        findsOneWidget,
      );
    });

    testWidgets('a corrupt stored value falls back rather than crashing', (
      tester,
    ) async {
      final settings = AppSettings(
        store: InMemorySettingsStore({
          'rehearse.simulation_difficulty': 'nonsense',
        }),
      );
      addTearDown(settings.dispose);

      await settings.load();
      expect(settings.difficulty, SimulationDifficulty.defensive);
    });
  });

  group('honesty', () {
    testWidgets('guided mode does not offer a control it cannot honour', (
      tester,
    ) async {
      await pumpBrief(tester);
      expect(find.byKey(const Key('difficulty_calm')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mode_guided')));
      await tester.pumpAndSettle();

      // Guided replies are authored, so resistance cannot vary. PRD §7.2
      // is explicit that a difficulty control must not be cosmetic.
      expect(find.byKey(const Key('difficulty_calm')), findsNothing);
      expect(find.byKey(const Key('difficulty_description')), findsNothing);

      await tester.tap(find.byKey(const Key('mode_freestyle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('difficulty_calm')), findsOneWidget);
    });
  });

  group('reaching the simulation', () {
    testWidgets('the chosen level is what the coach is asked for', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final coach = _RecordingCoach();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PracticeScreen(
            scenario: scenario,
            mode: PracticeMode.freestyle,
            difficulty: SimulationDifficulty.veryDefensive,
            coachService: coach,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('freeform_response')),
        'I need the handoff by Friday.',
      );
      await tester.tap(find.byKey(const Key('submit_response')));
      await tester.pumpAndSettle();

      expect(coach.asked, [SimulationDifficulty.veryDefensive]);
    });

    testWidgets('a retry keeps the level you picked', (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final coach = _RecordingCoach();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PracticeScreen(
            scenario: scenario,
            mode: PracticeMode.freestyle,
            difficulty: SimulationDifficulty.calm,
            coachService: coach,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < scenario.turns.length; i++) {
        await tester.enterText(
          find.byKey(const Key('freeform_response')),
          'I need the handoff by Friday. Which task moves?',
        );
        await tester.tap(find.byKey(const Key('submit_response')));
        await tester.pumpAndSettle();
      }

      await tester.scrollUntilVisible(
        find.byKey(const Key('retry_scenario')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('retry_scenario')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('freeform_response')),
        'Let us try that again, properly this time.',
      );
      await tester.tap(find.byKey(const Key('submit_response')));
      await tester.pumpAndSettle();

      expect(coach.asked.last, SimulationDifficulty.calm);
    });
  });

  group('the offline coach', () {
    test('cannot vary authored lines, but does vary how it lands', () async {
      final coach = OfflineCoachService();
      final history = [
        for (final _ in scenario.turns)
          PracticeResponse.spoken(
            text: 'ok',
            employeeReply: 'sure',
            source: EvaluationSource.offline,
          ),
      ];

      final closings = <String>{};
      for (final level in SimulationDifficulty.values) {
        final reply = await coach.respond(
          scenario: scenario,
          difficulty: level,
          // The last turn, where the conversation resolves.
          turnIndex: scenario.turns.length - 1,
          history: history,
          managerResponse: 'So are we agreed?',
        );
        closings.add(reply.text);
      }

      expect(
        closings,
        hasLength(3),
        reason: 'a very defensive person should not sign off like a calm one',
      );
    });

    test('mid-conversation lines stay authored whatever the level', () async {
      final coach = OfflineCoachService();

      for (final level in SimulationDifficulty.values) {
        final reply = await coach.respond(
          scenario: scenario,
          difficulty: level,
          turnIndex: 0,
          history: const [],
          managerResponse: 'We need to talk about the handoffs.',
        );
        expect(reply.text, scenario.turns[1].employeeLine);
      }
    });
  });
}

class _RecordingCoach implements CoachService {
  final List<SimulationDifficulty> asked = [];

  @override
  bool get isAiEnabled => true;

  @override
  Future<EmployeeReply> respond({
    required Scenario scenario,
    required SimulationDifficulty difficulty,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String managerResponse,
  }) async {
    asked.add(difficulty);
    return const EmployeeReply(
      text: 'That is not how I remember it.',
      source: EvaluationSource.ai,
    );
  }

  @override
  Future<PracticeSummary> evaluate({
    required Scenario scenario,
    required List<PracticeResponse> history,
  }) => OfflineCoachService().evaluate(scenario: scenario, history: history);
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
