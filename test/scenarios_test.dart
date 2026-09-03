import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';

/// Guards the authored content. Every scenario is hand-written, so these
/// check the shape the screens and the coach both rely on.
void main() {
  test('the library is not empty', () {
    expect(scenarios, isNotEmpty);
  });

  test('ids and characters are unique', () {
    expect(
      scenarios.map((scenario) => scenario.id).toSet(),
      hasLength(scenarios.length),
    );
    expect(
      scenarios.map((scenario) => scenario.personName).toSet(),
      hasLength(scenarios.length),
    );
  });

  for (final scenario in scenarios) {
    group(scenario.id, () {
      test('the briefing is filled in', () {
        for (final field in [
          scenario.title,
          scenario.subtitle,
          scenario.skill,
          scenario.personName,
          scenario.personRole,
          scenario.context,
          scenario.goal,
          scenario.watchFor,
        ]) {
          expect(field.trim(), isNotEmpty);
        }
        expect(scenario.personInitials, hasLength(2));
        expect(scenario.durationMinutes, greaterThan(0));
      });

      test('runs three turns and opens on the advertised line', () {
        expect(scenario.turns, hasLength(3));
        expect(scenario.turns.first.employeeLine, scenario.openingLine);
      });

      test('every turn offers a real choice', () {
        for (final turn in scenario.turns) {
          expect(turn.prompt.trim(), isNotEmpty);
          expect(turn.employeeLine.trim(), isNotEmpty);
          expect(turn.choices.length, greaterThanOrEqualTo(2));
          expect(
            turn.choices.map((choice) => choice.text).toSet(),
            hasLength(turn.choices.length),
          );
        }
      });

      test('every choice scores inside the range the coach uses', () {
        for (final choice in scenario.turns.expand((turn) => turn.choices)) {
          expect(choice.text.trim(), isNotEmpty);
          expect(choice.feedback.trim(), isNotEmpty);
          expect(choice.scoreDelta, inInclusiveRange(-10, 14));
          expect(choice.clarity, inInclusiveRange(-2, 2));
          expect(choice.empathy, inInclusiveRange(-2, 2));
          expect(choice.courage, inInclusiveRange(-2, 2));
        }
      });

      test('each turn has one clearly best answer', () {
        for (final turn in scenario.turns) {
          final deltas =
              turn.choices.map((choice) => choice.scoreDelta).toList()..sort();
          final best = deltas.last;
          final runnerUp = deltas[deltas.length - 2];

          expect(
            best,
            greaterThanOrEqualTo(8),
            reason: 'no strong option in "${turn.prompt}"',
          );
          expect(
            best - runnerUp,
            greaterThanOrEqualTo(4),
            reason: 'best and second-best are too close in "${turn.prompt}"',
          );
        }
      });

      test('the best path lands in the top band and the worst does not', () {
        PracticeSummary summarize(
          ResponseChoice Function(List<ResponseChoice>) pick,
        ) {
          return PracticeSummary.fromResponses([
            for (final turn in scenario.turns)
              PracticeResponse.fromChoice(pick(turn.choices)),
          ]);
        }

        final best = summarize(
          (choices) =>
              choices.reduce((a, b) => a.scoreDelta >= b.scoreDelta ? a : b),
        );
        final worst = summarize(
          (choices) =>
              choices.reduce((a, b) => a.scoreDelta <= b.scoreDelta ? a : b),
        );

        expect(best.score, greaterThanOrEqualTo(82));
        expect(worst.score, lessThan(52));
        expect(best.score - worst.score, greaterThanOrEqualTo(30));
      });
    });
  }
}
