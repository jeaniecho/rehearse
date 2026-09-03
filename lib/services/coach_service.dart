import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/practice_response.dart';
import '../models/scenario.dart';

abstract interface class CoachService {
  bool get isAiEnabled;

  Future<PracticeResponse> evaluate({
    required Scenario scenario,
    required DialogueTurn turn,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String responseText,
  });
}

CoachService createCoachService({http.Client? client}) {
  const endpoint = String.fromEnvironment('REHEARSE_COACH_URL');
  final offline = OfflineCoachService();
  if (endpoint.trim().isEmpty) return offline;

  return ResilientCoachService(
    primary: RemoteCoachService(
      baseUrl: endpoint,
      client: client ?? http.Client(),
    ),
    fallback: offline,
  );
}

class RemoteCoachService implements CoachService {
  RemoteCoachService({required String baseUrl, required this.client})
    : _endpoint = Uri.parse(
        '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/evaluate',
      ),
      _sessionId = _makeSessionId();

  final http.Client client;
  final Uri _endpoint;
  final String _sessionId;

  @override
  bool get isAiEnabled => true;

  @override
  Future<PracticeResponse> evaluate({
    required Scenario scenario,
    required DialogueTurn turn,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String responseText,
  }) async {
    final response = await client
        .post(
          _endpoint,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'sessionId': _sessionId,
            'scenario': {
              'id': scenario.id,
              'title': scenario.title,
              'context': scenario.context,
              'goal': scenario.goal,
              'watchFor': scenario.watchFor,
              'personName': scenario.personName,
              'personRole': scenario.personRole,
            },
            'turn': {
              'index': turnIndex,
              'employeeLine': turn.employeeLine,
              'prompt': turn.prompt,
              'isLast': turnIndex == scenario.turns.length - 1,
            },
            'history': [
              for (final item in history)
                {
                  'managerResponse': item.text,
                  'employeeReply': item.employeeReply,
                },
            ],
            'managerResponse': responseText,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw CoachServiceException(
        'Coach returned status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Coach returned an invalid response.');
    }

    return PracticeResponse.fromJson(
      decoded,
      text: responseText,
      source: EvaluationSource.ai,
    );
  }

  static String _makeSessionId() {
    final random = Random.secure();
    return [
      DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      random.nextInt(1 << 32).toRadixString(36),
      random.nextInt(1 << 32).toRadixString(36),
    ].join('-');
  }
}

class ResilientCoachService implements CoachService {
  const ResilientCoachService({required this.primary, required this.fallback});

  final CoachService primary;
  final CoachService fallback;

  @override
  bool get isAiEnabled => primary.isAiEnabled;

  @override
  Future<PracticeResponse> evaluate({
    required Scenario scenario,
    required DialogueTurn turn,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String responseText,
  }) async {
    try {
      return await primary.evaluate(
        scenario: scenario,
        turn: turn,
        turnIndex: turnIndex,
        history: history,
        responseText: responseText,
      );
    } on Object {
      return fallback.evaluate(
        scenario: scenario,
        turn: turn,
        turnIndex: turnIndex,
        history: history,
        responseText: responseText,
      );
    }
  }
}

class OfflineCoachService implements CoachService {
  @override
  bool get isAiEnabled => false;

  static const _stopWords = {
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'but',
    'for',
    'i',
    'in',
    'is',
    'it',
    'of',
    'on',
    'or',
    'that',
    'the',
    'this',
    'to',
    'we',
    'with',
    'you',
  };

  @override
  Future<PracticeResponse> evaluate({
    required Scenario scenario,
    required DialogueTurn turn,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String responseText,
  }) async {
    final closest = _closestChoice(turn.choices, responseText);
    final employeeReply = turnIndex < scenario.turns.length - 1
        ? scenario.turns[turnIndex + 1].employeeLine
        : 'Okay. I understand what we’re agreeing to.';

    if (closest.$2 >= 0.2) {
      final choice = closest.$1;
      return PracticeResponse(
        text: responseText,
        scoreDelta: choice.scoreDelta,
        feedback: choice.feedback,
        clarity: choice.clarity,
        empathy: choice.empathy,
        directness: choice.directness,
        confidence: choice.confidence,
        source: EvaluationSource.offline,
        employeeReply: employeeReply,
      );
    }

    final lower = responseText.toLowerCase();
    final clarity = _signalScore(lower, const [
      'need',
      'expect',
      'agree',
      'deadline',
      'impact',
      'next step',
      'by ',
    ]);
    final empathy = _signalScore(lower, const [
      'understand',
      'hear',
      'see',
      'appreciate',
      'sorry',
      'help',
    ]);
    final directness = _signalScore(lower, const [
      'need',
      'cannot',
      'can’t',
      'will not',
      'expect',
      'impact',
      'tradeoff',
    ]);
    // Conviction reads as committing to something; hedging reads as giving
    // ground before anyone has pushed.
    final confidence = _hedgeScore(lower);
    final scoreDelta =
        (((clarity + empathy + directness + confidence) * 2.5).round()).clamp(
          -6,
          12,
        );

    return PracticeResponse(
      text: responseText,
      scoreDelta: scoreDelta,
      feedback: _feedbackFor(
        clarity: clarity,
        empathy: empathy,
        directness: directness,
        confidence: confidence,
      ),
      clarity: clarity,
      empathy: empathy,
      directness: directness,
      confidence: confidence,
      source: EvaluationSource.offline,
      employeeReply: employeeReply,
    );
  }

  (ResponseChoice, double) _closestChoice(
    List<ResponseChoice> choices,
    String response,
  ) {
    final responseTokens = _tokens(response);
    var best = choices.first;
    var bestScore = 0.0;

    for (final choice in choices) {
      final choiceTokens = _tokens(choice.text);
      final union = responseTokens.union(choiceTokens);
      final overlap = responseTokens.intersection(choiceTokens);
      final score = union.isEmpty ? 0.0 : overlap.length / union.length;
      if (score > bestScore) {
        best = choice;
        bestScore = score;
      }
    }
    return (best, bestScore);
  }

  Set<String> _tokens(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9’]+'))
        .where((word) => word.length > 1 && !_stopWords.contains(word))
        .toSet();
  }

  int _signalScore(String value, List<String> signals) {
    final matches = signals.where(value.contains).length;
    return switch (matches) {
      0 => -1,
      1 => 1,
      _ => 2,
    };
  }

  /// Hedges cost conviction; a plain commitment earns it.
  int _hedgeScore(String value) {
    const hedges = [
      'maybe',
      'sort of',
      'kind of',
      'i guess',
      'i think maybe',
      'if that’s ok',
      'if that works',
      'just wondering',
      'do your best',
      'we’ll see',
      'sorry to bother',
    ];
    const commitments = ['i need', 'i expect', 'we will', 'i will', 'by '];

    final hedged = hedges.where(value.contains).length;
    final committed = commitments.where(value.contains).length;
    if (hedged > 0 && committed == 0) return -2;
    if (hedged > 0) return 0;
    return committed > 0 ? 2 : -1;
  }

  String _feedbackFor({
    required int clarity,
    required int empathy,
    required int directness,
    required int confidence,
  }) {
    if (confidence < 0 && clarity >= 1) {
      return 'The point is there, but the hedging around it invites a negotiation you did not intend to open.';
    }
    if (clarity >= 1 && empathy >= 1 && directness >= 1) {
      return 'You balanced a clear message with acknowledgment and a concrete way forward.';
    }
    if (clarity < 1) {
      return 'Your intent is thoughtful. Name the specific issue and the next step so it is easier to act on.';
    }
    if (empathy < 1) {
      return 'The message is direct. Add one sentence that shows you heard the pressure or impact on the other person.';
    }
    if (directness < 1) {
      return 'You showed care and clarity. State the boundary or expectation more directly so it cannot be missed.';
    }
    return 'You showed care and clarity. State the boundary or expectation more directly so it cannot be missed.';
  }
}

class CoachServiceException implements Exception {
  const CoachServiceException(this.message);

  final String message;

  @override
  String toString() => 'CoachServiceException: $message';
}
