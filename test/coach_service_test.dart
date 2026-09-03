import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rehearse/data/scenarios.dart';
import 'package:rehearse/models/practice_response.dart';
import 'package:rehearse/services/coach_service.dart';

void main() {
  test('remote coach sends context and parses structured feedback', () async {
    late Map<String, dynamic> requestBody;
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://coach.example/evaluate');
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'score_delta': 12,
          'feedback': 'You paired acknowledgment with a clear expectation.',
          'clarity': 2,
          'empathy': 2,
          'courage': 1,
          'employee_reply': 'I can flag the risk sooner.',
        }),
        200,
      );
    });
    final service = RemoteCoachService(
      baseUrl: 'https://coach.example/',
      client: client,
    );

    final result = await service.evaluate(
      scenario: scenarios.first,
      turn: scenarios.first.turns.first,
      turnIndex: 0,
      history: const [],
      responseText:
          'I see how much you have taken on. We still need to address the two missed handoffs.',
    );

    expect(requestBody['managerResponse'], contains('missed handoffs'));
    expect(requestBody['scenario']['id'], 'missed-deadlines');
    expect(result.source, EvaluationSource.ai);
    expect(result.scoreDelta, 12);
    expect(result.employeeReply, 'I can flag the risk sooner.');
  });

  test('resilient coach falls back when the remote endpoint fails', () async {
    final service = ResilientCoachService(
      primary: RemoteCoachService(
        baseUrl: 'https://coach.example',
        client: MockClient((_) async => http.Response('unavailable', 503)),
      ),
      fallback: OfflineCoachService(),
    );

    final result = await service.evaluate(
      scenario: scenarios.first,
      turn: scenarios.first.turns.first,
      turnIndex: 0,
      history: const [],
      responseText:
          'I see how much you have taken on. We need to discuss the impact and agree on a next step.',
    );

    expect(result.source, EvaluationSource.offline);
    expect(result.feedback, isNotEmpty);
  });
}
