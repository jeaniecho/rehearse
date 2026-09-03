import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/models/scenario.dart';
import 'package:rehearse/models/practice_summary.dart';
import 'package:rehearse/services/coach_service.dart';

final scenario = scenarios.first;

const _said =
    'I see how much you have taken on. We still need to address the two '
    'missed handoffs.';

PracticeResponse turn(String text, {String reply = 'The scope keeps moving.'}) {
  return PracticeResponse.spoken(
    text: text,
    employeeReply: reply,
    source: EvaluationSource.ai,
  );
}

Map<String, Object?> evaluationBody({
  List<Map<String, Object?>> strengths = const [],
  List<Map<String, Object?>> improvements = const [],
  String summary = 'You held both sides of it.',
}) => {
  'overall_score': 74,
  'clarity': 68,
  'empathy': 90,
  'directness': 62,
  'confidence': 71,
  'summary': summary,
  'strengths': strengths,
  'improvements': improvements,
};

void main() {
  group('simulation', () {
    test(
      'asks the employee to reply and sends no request for a score',
      () async {
        late Uri url;
        late Map<String, dynamic> body;
        final client = MockClient((request) async {
          url = request.url;
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'reply': 'The scope keeps moving.',
              'emotion': 'defensive',
            }),
            200,
          );
        });

        final reply =
            await RemoteCoachService(
              baseUrl: 'https://coach.example/',
              client: client,
            ).respond(
              scenario: scenario,
              difficulty: SimulationDifficulty.defensive,
              turnIndex: 0,
              history: const [],
              managerResponse: _said,
            );

        expect(url.toString(), 'https://coach.example/simulation/respond');
        expect(body['managerResponse'], contains('missed handoffs'));
        expect(body['scenario']['id'], 'missed-deadlines');
        expect(reply.text, 'The scope keeps moving.');
        expect(reply.source, EvaluationSource.ai);
      },
    );

    test('an empty reply is treated as a failure', () async {
      final service = RemoteCoachService(
        baseUrl: 'https://coach.example',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'reply': '   '}), 200),
        ),
      );

      expect(
        () => service.respond(
          scenario: scenario,
          difficulty: SimulationDifficulty.defensive,
          turnIndex: 0,
          history: const [],
          managerResponse: _said,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('falls back to the authored line when the remote fails', () async {
      final service = ResilientCoachService(
        primary: RemoteCoachService(
          baseUrl: 'https://coach.example',
          client: MockClient((_) async => http.Response('nope', 503)),
        ),
        fallback: OfflineCoachService(),
      );

      final reply = await service.respond(
        scenario: scenario,
        difficulty: SimulationDifficulty.defensive,
        turnIndex: 0,
        history: const [],
        managerResponse: _said,
      );

      expect(reply.source, EvaluationSource.offline);
      expect(reply.text, scenario.turns[1].employeeLine);
    });
  });

  group('evaluation', () {
    test('scores the whole transcript in one call', () async {
      late Uri url;
      late Map<String, dynamic> body;
      final client = MockClient((request) async {
        url = request.url;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(evaluationBody()), 200);
      });

      final summary = await RemoteCoachService(
        baseUrl: 'https://coach.example',
        client: client,
      ).evaluate(scenario: scenario, history: [turn(_said)]);

      expect(url.toString(), 'https://coach.example/simulation/evaluate');
      expect((body['history'] as List), hasLength(1));
      expect(summary.score, 74);
      expect(summary.empathy, 90);
      expect(summary.confidence, 71);
      expect(summary.usedAi, isTrue);
      expect(summary.summary, 'You held both sides of it.');
    });

    test('keeps a grounded quote and drops an invented one', () {
      final summary = parseEvaluation(
        evaluationBody(
          strengths: [
            {
              'turn_index': 0,
              'quote': 'I see how much you have taken on',
              'comment': 'You led with the pressure they are under.',
              'suggestion': '',
            },
          ],
          improvements: [
            {
              'turn_index': 0,
              'quote': 'let us circle back next week',
              'comment': 'Never said.',
              'suggestion': 'Name the date.',
            },
          ],
        ),
        history: [turn(_said)],
      );

      expect(summary.strengths, hasLength(1));
      expect(
        summary.strengths.single.quote,
        'I see how much you have taken on',
      );
      expect(summary.strengths.single.suggestion, isNull);
      expect(
        summary.improvements,
        isEmpty,
        reason: 'a critique of words nobody said must never be shown',
      );
    });

    test('grounding survives punctuation and smart quotes', () {
      final summary = parseEvaluation(
        evaluationBody(
          improvements: [
            {
              'turn_index': 0,
              'quote': '“We still need, to address the two missed handoffs!”',
              'comment': 'Still theirs.',
              'suggestion': 'Try naming the date.',
            },
          ],
        ),
        history: [turn(_said)],
      );

      expect(summary.improvements, hasLength(1));
      expect(summary.improvements.single.suggestion, 'Try naming the date.');
    });

    test('at most three notes of each kind survive', () {
      final many = [
        for (var i = 0; i < 6; i++)
          {
            'turn_index': 0,
            'quote': 'missed handoffs',
            'comment': 'note $i',
            'suggestion': '',
          },
      ];

      final summary = parseEvaluation(
        evaluationBody(improvements: many),
        history: [turn(_said)],
      );

      expect(summary.improvements, hasLength(3));
    });

    test('a missing score is a format error, not a silent zero', () {
      final body = evaluationBody()..remove('confidence');
      expect(
        () => parseEvaluation(body, history: [turn(_said)]),
        throwsA(isA<FormatException>()),
      );
    });

    test('a malformed payload degrades to the offline coach', () async {
      final service = ResilientCoachService(
        primary: RemoteCoachService(
          baseUrl: 'https://coach.example',
          client: MockClient((_) async => http.Response('{"nope":1}', 200)),
        ),
        fallback: OfflineCoachService(),
      );

      final summary = await service.evaluate(
        scenario: scenario,
        history: [turn(_said)],
      );

      expect(summary.usedAi, isFalse);
      expect(summary.score, inInclusiveRange(0, 100));
    });
  });

  group('the offline coach', () {
    test('quotes the manager and suggests authored wording', () async {
      final summary = await OfflineCoachService().evaluate(
        scenario: scenario,
        history: [
          turn(_said),
          turn('Just do your best and keep me posted.'),
          turn('I need the handoff by Friday. Which task moves to make room?'),
        ],
      );

      expect(summary.usedAi, isFalse);
      expect(summary.strengths, isNotEmpty);
      expect(summary.improvements, isNotEmpty);

      final improvement = summary.improvements.single;
      // The quote is the manager's own words, never a paraphrase.
      expect(
        [for (final note in summary.strengths) note.quote] +
            [improvement.quote],
        everyElement(
          anyOf(
            _said,
            'Just do your best and keep me posted.',
            'I need the handoff by Friday. Which task moves to make room?',
          ),
        ),
      );
      // With no network, stronger wording still comes from the authored
      // content rather than being fabricated.
      expect(improvement.suggestion, isNotNull);
      expect(
        scenario.turns[improvement.turnIndex].choices.map((c) => c.text),
        contains(improvement.suggestion),
      );
    });

    test('scores every dimension inside the 0-100 range', () async {
      final summary = await OfflineCoachService().evaluate(
        scenario: scenario,
        history: [turn('ok')],
      );

      for (final value in summary.skills.values) {
        expect(value, inInclusiveRange(0, 100));
      }
      expect(summary.score, inInclusiveRange(0, 100));
    });
  });

  group('falling back', () {
    test('a silent degradation is still reported', () async {
      final reported = <String>[];
      final service = ResilientCoachService(
        primary: RemoteCoachService(
          baseUrl: 'https://coach.example',
          client: MockClient((_) async => http.Response('nope', 503)),
        ),
        fallback: OfflineCoachService(),
        onFallback: (error, stackTrace, operation) => reported.add(operation),
      );

      await service.respond(
        scenario: scenario,
        difficulty: SimulationDifficulty.defensive,
        turnIndex: 0,
        history: const [],
        managerResponse: _said,
      );
      await service.evaluate(scenario: scenario, history: [turn(_said)]);

      // The person practising sees only a badge change; whoever runs the
      // service should not have to find out from a review.
      expect(reported, ['respond', 'evaluate']);
    });

    test('a working coach reports nothing', () async {
      var reports = 0;
      final service = ResilientCoachService(
        primary: RemoteCoachService(
          baseUrl: 'https://coach.example',
          client: MockClient(
            (_) async => http.Response(jsonEncode({'reply': 'Fine.'}), 200),
          ),
        ),
        fallback: OfflineCoachService(),
        onFallback: (_, _, _) => reports++,
      );

      await service.respond(
        scenario: scenario,
        difficulty: SimulationDifficulty.calm,
        turnIndex: 0,
        history: const [],
        managerResponse: _said,
      );

      expect(reports, 0);
    });
  });

  group('guided mode', () {
    test('builds notes from the authored choices, with a stronger option', () {
      final weakest = scenario.turns.first.choices.reduce(
        (a, b) => a.scoreDelta <= b.scoreDelta ? a : b,
      );
      final best = scenario.turns.first.choices.reduce(
        (a, b) => a.scoreDelta >= b.scoreDelta ? a : b,
      );

      final summary = PracticeSummary.fromResponses([
        PracticeResponse.fromChoice(weakest, scenario.turns.first),
      ]);

      expect(summary.improvements, hasLength(1));
      expect(summary.improvements.single.quote, weakest.text);
      expect(summary.improvements.single.suggestion, best.text);
      expect(summary.strengths, isEmpty);
    });

    test('the best choice needs no rewrite', () {
      final best = scenario.turns.first.choices.reduce(
        (a, b) => a.scoreDelta >= b.scoreDelta ? a : b,
      );

      final summary = PracticeSummary.fromResponses([
        PracticeResponse.fromChoice(best, scenario.turns.first),
      ]);

      expect(summary.strengths.single.quote, best.text);
      expect(summary.strengths.single.suggestion, isNull);
    });
  });
}
