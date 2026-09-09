import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_record.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/models/session_outcome.dart';
import 'package:rehearse/screens/practice_screen.dart';
import 'package:rehearse/screens/results_screen.dart';
import 'package:rehearse/services/coach_service.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/widgets/rehearse_scope.dart';

/// PRD §9 (how a conversation ends) and §11 (the outcome the report must
/// show). The two are deliberately separate: §9 decides whether there is
/// another turn, §11 is a judgement on the finished transcript.
void main() {
  final scenario = scenarios.first;

  ResponseChoice closing(SessionOutcome outcome) => scenario.turns.last.choices
      .firstWhere((choice) => choice.resolution == outcome);

  PracticeSummary guidedEndingOn(ResponseChoice last) {
    return PracticeSummary.fromResponses([
      for (var i = 0; i < scenario.turns.length; i++)
        PracticeResponse.fromChoice(
          i == scenario.turns.length - 1
              ? last
              : scenario.turns[i].choices.first,
          scenario.turns[i],
        ),
    ]);
  }

  group('guided mode takes the outcome from the authored close', () {
    test('the closing choice decides it, not the running score', () {
      // The same three-turn path, differing only in the last move. If the
      // outcome tracked the score this would be impossible to assert.
      for (final outcome in SessionOutcome.values) {
        final choice = scenario.turns.last.choices
            .where((c) => c.resolution == outcome)
            .firstOrNull;
        if (choice == null) continue;
        expect(guidedEndingOn(choice).outcome, outcome);
      }
    });

    test('a strong conversation can still end unresolved', () {
      // The point PRD §9 is making — "the product should not require perfect
      // resolution". Score and outcome have to be able to disagree.
      final weakClose = scenario.turns.last.choices.reduce(
        (a, b) => a.scoreDelta <= b.scoreDelta ? a : b,
      );
      final summary = PracticeSummary.fromResponses([
        for (var i = 0; i < scenario.turns.length; i++)
          PracticeResponse.fromChoice(
            i == scenario.turns.length - 1
                ? weakClose
                : scenario.turns[i].choices.reduce(
                    (a, b) => a.scoreDelta >= b.scoreDelta ? a : b,
                  ),
            scenario.turns[i],
          ),
      ]);

      expect(summary.score, greaterThan(50));
      expect(summary.outcome, isNot(SessionOutcome.success));
    });
  });

  group('the simulation can end the conversation early', () {
    Future<_Coach> runFreeform(
      WidgetTester tester, {
      required SimulationResolution declare,
      required int declareAtTurn,
    }) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final coach = _Coach(declare: declare, declareAtTurn: declareAtTurn);
      await tester.pumpWidget(
        RehearseScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: PracticeScreen(
              scenario: scenario,
              mode: PracticeMode.freestyle,
              coachService: coach,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < scenario.turns.length; i++) {
        final field = find.byKey(const Key('freeform_response'));
        if (field.evaluate().isEmpty) break;
        await tester.enterText(field, 'Here is what I need to say, turn $i.');
        await tester.tap(find.byKey(const Key('submit_response')));
        await tester.pumpAndSettle();
      }
      return coach;
    }

    testWidgets(
      'a resolution on a later turn ends it before the turns run out',
      (tester) async {
        final coach = await runFreeform(
          tester,
          declare: SimulationResolution.resolved,
          declareAtTurn: 1,
        );

        expect(coach.turnsAsked, 2, reason: 'should have stopped after turn 2');
        expect(find.byType(ResultsScreen), findsOneWidget);
      },
    );

    testWidgets('a breakdown ends it too', (tester) async {
      final coach = await runFreeform(
        tester,
        declare: SimulationResolution.breakdown,
        declareAtTurn: 1,
      );

      expect(coach.turnsAsked, 2);
      expect(find.byType(ResultsScreen), findsOneWidget);
    });

    testWidgets('the opening exchange cannot resolve it', (tester) async {
      // One message is not a rehearsal. A model that declares victory on the
      // first turn would take away the practice the person came for.
      final coach = await runFreeform(
        tester,
        declare: SimulationResolution.resolved,
        declareAtTurn: 0,
      );

      expect(coach.turnsAsked, scenario.turns.length);
    });

    testWidgets('otherwise the turns run out, as before', (tester) async {
      final coach = await runFreeform(
        tester,
        declare: SimulationResolution.continuing,
        declareAtTurn: 0,
      );

      expect(coach.turnsAsked, scenario.turns.length);
      expect(find.byType(ResultsScreen), findsOneWidget);
    });
  });

  group('the coach supplies the outcome', () {
    test('the remote evaluation is read straight through', () {
      final summary = parseEvaluation({
        'overall_score': 88,
        'clarity': 80,
        'empathy': 80,
        'directness': 80,
        'confidence': 80,
        'summary': 'It landed.',
        'outcome': 'escalated',
        'strengths': <Object>[],
        'improvements': <Object>[],
      }, history: const []);

      // 88 is the top band. The outcome still has to be what the coach said.
      expect(summary.score, 88);
      expect(summary.outcome, SessionOutcome.escalated);
    });

    test('an unreadable outcome does not become a flattering one', () {
      for (final bad in [null, 'triumphant', 42]) {
        final summary = parseEvaluation({
          'overall_score': 95,
          'clarity': 95,
          'empathy': 95,
          'directness': 95,
          'confidence': 95,
          'summary': '',
          'outcome': bad,
          'strengths': <Object>[],
          'improvements': <Object>[],
        }, history: const []);

        expect(summary.outcome, SessionOutcome.unresolved);
      }
    });

    test(
      'the offline coach borrows the authored close, not the score',
      () async {
        final resolves = closing(SessionOutcome.success);
        final summary = await OfflineCoachService().evaluate(
          scenario: scenario,
          history: [
            for (var i = 0; i < scenario.turns.length - 1; i++)
              PracticeResponse.spoken(
                text: scenario.turns[i].choices.first.text,
                employeeReply: scenario.turns[i + 1].employeeLine,
                source: EvaluationSource.offline,
              ),
            PracticeResponse.spoken(
              text: resolves.text,
              employeeReply: 'Understood.',
              source: EvaluationSource.offline,
            ),
          ],
        );

        expect(summary.outcome, SessionOutcome.success);
      },
    );

    test('wording it cannot recognise is left unresolved', () async {
      final summary = await OfflineCoachService().evaluate(
        scenario: scenario,
        history: [
          PracticeResponse.spoken(
            text: 'Pangolin xylophone quarry.',
            employeeReply: 'What?',
            source: EvaluationSource.offline,
          ),
        ],
      );

      expect(summary.outcome, SessionOutcome.unresolved);
    });
  });

  group('history keeps it', () {
    test('an outcome survives a round trip', () {
      final record = PracticeRecord(
        scenarioId: scenario.id,
        completedAt: DateTime.utc(2026, 9, 9),
        mode: PracticeMode.guided,
        score: 70,
        clarity: 70,
        empathy: 70,
        directness: 70,
        confidence: 70,
        usedAi: false,
        outcome: SessionOutcome.partial,
      );

      final restored = PracticeRecord.tryFromJson(record.toJson());
      expect(restored?.outcome, SessionOutcome.partial);
    });

    test(
      'records written before outcomes existed keep a null, not a guess',
      () {
        final restored = PracticeRecord.tryFromJson({
          'scenarioId': scenario.id,
          'completedAt': '2026-01-01T00:00:00.000Z',
          'mode': 'guided',
          'score': 91,
          'clarity': 91,
          'empathy': 91,
          'directness': 91,
          'usedAi': false,
        });

        // A high score must not be back-filled into "resolved" — nothing
        // measured how that conversation ended.
        expect(restored, isNotNull);
        expect(restored!.outcome, isNull);
      },
    );
  });

  testWidgets('the report shows it', (tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      RehearseScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: ResultsScreen(
            scenario: scenario,
            summary: guidedEndingOn(closing(SessionOutcome.unresolved)),
            mode: PracticeMode.guided,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session_outcome')), findsOneWidget);
    expect(
      find.text(SessionOutcome.unresolved.label.toUpperCase()),
      findsOneWidget,
    );
  });
}

/// Declares [declare] on exactly [declareAtTurn], and counts how many turns
/// the screen actually asked for.
class _Coach implements CoachService {
  _Coach({required this.declare, required this.declareAtTurn});

  final SimulationResolution declare;
  final int declareAtTurn;
  int turnsAsked = 0;

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
    turnsAsked += 1;
    return EmployeeReply(
      text: 'Understood.',
      source: EvaluationSource.ai,
      resolution: turnIndex == declareAtTurn
          ? declare
          : SimulationResolution.continuing,
    );
  }

  @override
  Future<PracticeSummary> evaluate({
    required Scenario scenario,
    required List<PracticeResponse> history,
  }) => OfflineCoachService().evaluate(scenario: scenario, history: history);
}
