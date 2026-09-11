import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/models/session_outcome.dart';
import 'package:rehearse/services/subscription.dart';
import 'package:rehearse/widgets/illustration.dart';

/// Guards the authored content. Every scenario is hand-written, so these
/// check the shape the screens and the coach both rely on.
void main() {
  test('the library is not empty', () {
    expect(scenarios, isNotEmpty);
  });

  test('the free tier names scenarios that exist', () {
    // The free tier is a set of ids rather than a flag on each scenario, so
    // nothing in the type system stops a typo or a renamed scenario from
    // silently closing the library to everyone who has not paid.
    final ids = {for (final scenario in scenarios) scenario.id};

    expect(Subscription.freeScenarioIds, isNotEmpty);
    expect(
      Subscription.freeScenarioIds.difference(ids),
      isEmpty,
      reason: 'a free scenario id matches nothing in the library',
    );
    expect(
      Subscription.freeScenarioIds.length,
      lessThan(scenarios.length),
      reason: 'Pro has to unlock something',
    );
  });

  test('the free scenarios are the gentlest in the library', () {
    // Someone meets the product through these two, so neither should be a
    // high-stakes conversation opened cold.
    for (final id in Subscription.freeScenarioIds) {
      final scenario = scenarios.firstWhere((s) => s.id == id);
      expect(
        scenario.stakes,
        ScenarioStakes.warmUp,
        reason: '$id is the wrong weight for a first impression',
      );
    }
  });

  test('confidence is scored as its own axis, not a copy of directness', () {
    // The two come apart in real conversations — blunt but rattled, or
    // gentle but immovable — and the rubric is worthless if the authored
    // content treats them as the same number.
    final choices = [
      for (final scenario in scenarios)
        for (final turn in scenario.turns) ...turn.choices,
    ];
    final differing = choices
        .where((choice) => choice.confidence != choice.directness)
        .length;

    expect(
      differing / choices.length,
      greaterThan(0.25),
      reason:
          'confidence tracks directness too closely to be measuring '
          'anything of its own',
    );
  });

  test('every outcome the report can show is reachable', () {
    // A value the authored library never produces is a label nobody will
    // ever see, and a branch nothing exercises.
    final authored = {
      for (final scenario in scenarios)
        for (final choice in scenario.turns.last.choices) ?choice.resolution,
    };

    expect(authored, containsAll(SessionOutcome.values));
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

  test('every scenario has a mark, and the set has nothing spare', () {
    // Filenames are keyed by scenario id, so this is the only thing
    // standing between a new scenario and a blank space in the home list.
    expect(
      Illustration.names.toSet(),
      containsAll(scenarios.map((scenario) => scenario.id)),
    );
    expect(
      Illustration.names.toSet().difference(
        scenarios.map((scenario) => scenario.id).toSet(),
      ),
      {'empty-progress', 'pro-unlock', 'logo'},
      reason: 'a mark nothing references is dead weight in the bundle',
    );
  });

  for (final name in Illustration.names) {
    test('$name is derived at every pixel ratio', () {
      // The masters in art/ do not ship. If the variants are missing or
      // stale, run `flutter test tool/generate_illustrations.dart`.
      expect(File('art/illustrations/$name.png').existsSync(), isTrue);
      for (final variant in ['', '2.0x/', '3.0x/']) {
        expect(
          File('${Illustration.directory}/$variant$name.png').existsSync(),
          isTrue,
          reason: 'missing the ${variant.isEmpty ? '1.0x' : variant} variant',
        );
      }
    });
  }

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
          expect(choice.directness, inInclusiveRange(-2, 2));
          expect(choice.confidence, inInclusiveRange(-2, 2));
          expect(choice.confidence, inInclusiveRange(-2, 2));
        }
      });

      test('the closing turn says how it lands, and only the closing turn', () {
        // PRD §9's outcome is authored on the last move because a guided
        // conversation cannot end early — see `ResponseChoice.resolution`.
        for (final choice in scenario.turns.last.choices) {
          expect(
            choice.resolution,
            isNotNull,
            reason: 'no outcome for "${choice.text}"',
          );
        }

        for (final turn in scenario.turns.take(scenario.turns.length - 1)) {
          for (final choice in turn.choices) {
            expect(
              choice.resolution,
              isNull,
              reason:
                  'a mid-conversation choice cannot end anything: '
                  '"${choice.text}"',
            );
          }
        }
      });

      test('the best close resolves it and the worst does not', () {
        final closing = scenario.turns.last.choices;
        final best = closing.reduce(
          (a, b) => a.scoreDelta >= b.scoreDelta ? a : b,
        );
        final worst = closing.reduce(
          (a, b) => a.scoreDelta <= b.scoreDelta ? a : b,
        );

        expect(best.resolution, SessionOutcome.success);
        expect(worst.resolution, isNot(SessionOutcome.success));
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
              PracticeResponse.fromChoice(pick(turn.choices), turn),
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
