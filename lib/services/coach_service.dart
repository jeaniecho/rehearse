import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/coaching_note.dart';
import '../models/practice_response.dart';
import '../models/practice_summary.dart';
import '../models/scenario.dart';
import 'crash_reporter.dart';

/// What the other person says back, and nothing else.
///
/// Separate from any judgement on purpose: PRD §7.3 says the simulation must
/// not coach while it is running, because a narrator explaining your mistake
/// mid-sentence is the opposite of the pressure the product exists to
/// recreate.
class EmployeeReply {
  const EmployeeReply({required this.text, required this.source});

  final String text;
  final EvaluationSource source;
}

/// The coach: two distinct jobs, deliberately not one prompt.
abstract interface class CoachService {
  bool get isAiEnabled;

  /// Continues the conversation in character.
  Future<EmployeeReply> respond({
    required Scenario scenario,
    required SimulationDifficulty difficulty,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String managerResponse,
  });

  /// Reads the finished transcript once and scores it as a whole.
  Future<PracticeSummary> evaluate({
    required Scenario scenario,
    required List<PracticeResponse> history,
  });
}

CoachService createCoachService({http.Client? client, CrashReporter? crashes}) {
  const endpoint = String.fromEnvironment('REHEARSE_COACH_URL');
  final offline = OfflineCoachService();
  if (endpoint.trim().isEmpty) return offline;

  final reporter = crashes ?? createCrashReporter();
  return ResilientCoachService(
    primary: RemoteCoachService(
      baseUrl: endpoint,
      client: client ?? http.Client(),
    ),
    fallback: offline,
    // Falling back is invisible in the UI beyond a badge, which is right for
    // the person practising and wrong for whoever is running the service. A
    // coach that is quietly down in production should be noticed.
    onFallback: (error, stackTrace, operation) => reporter.reportHandled(
      error,
      stackTrace: stackTrace,
      context: 'coach.$operation',
    ),
  );
}

class RemoteCoachService implements CoachService {
  RemoteCoachService({required String baseUrl, required this.client})
    : _base = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _sessionId = _makeSessionId();

  final http.Client client;
  final String _base;
  final String _sessionId;

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
    final decoded = await _post('/simulation/respond', {
      'sessionId': _sessionId,
      'scenario': _scenarioJson(scenario),
      'difficulty': difficulty.name,
      'turn': {
        'index': turnIndex,
        'isLast': turnIndex == scenario.turns.length - 1,
      },
      'history': _historyJson(history),
      'managerResponse': managerResponse,
    }, timeout: const Duration(seconds: 15));

    final reply = decoded['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const FormatException('Coach returned no reply.');
    }
    return EmployeeReply(text: reply.trim(), source: EvaluationSource.ai);
  }

  @override
  Future<PracticeSummary> evaluate({
    required Scenario scenario,
    required List<PracticeResponse> history,
  }) async {
    // The whole transcript is being read, so this is slower than a turn and
    // is allowed to be.
    final decoded = await _post('/simulation/evaluate', {
      'sessionId': _sessionId,
      'scenario': _scenarioJson(scenario),
      'history': _historyJson(history),
    }, timeout: const Duration(seconds: 30));

    return parseEvaluation(decoded, history: history);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body, {
    required Duration timeout,
  }) async {
    final response = await client
        .post(
          Uri.parse('$_base$path'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw CoachServiceException(
        'Coach returned status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Coach returned an invalid response.');
    }
    return decoded;
  }

  static Map<String, Object?> _scenarioJson(Scenario scenario) => {
    'id': scenario.id,
    'title': scenario.title,
    'context': scenario.context,
    'goal': scenario.goal,
    'watchFor': scenario.watchFor,
    'personName': scenario.personName,
    'personRole': scenario.personRole,
    'openingLine': scenario.openingLine,
  };

  static List<Map<String, Object?>> _historyJson(
    List<PracticeResponse> history,
  ) => [
    for (var index = 0; index < history.length; index++)
      {
        'turnIndex': index,
        'managerResponse': history[index].text,
        'employeeReply': history[index].employeeReply,
      },
  ];

  static String _makeSessionId() {
    final random = Random.secure();
    return [
      DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      random.nextInt(1 << 32).toRadixString(36),
      random.nextInt(1 << 32).toRadixString(36),
    ].join('-');
  }
}

/// Turns an `/simulation/evaluate` payload into a summary, dropping any note
/// whose quote is not actually in the transcript.
PracticeSummary parseEvaluation(
  Map<String, dynamic> json, {
  required List<PracticeResponse> history,
}) {
  int score(String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('Coach response is missing $key.');
    }
    return value.round().clamp(0, 100);
  }

  final managerTurns = [for (final item in history) item.text];

  List<CoachingNote> notes(String key) {
    final raw = json[key];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (CoachingNote.tryFromJson(item, turnCount: history.length)
            case final note?)
          // A critique of words nobody said would poison the one thing this
          // report has to get right.
          if (note.isGroundedIn(managerTurns)) note,
    ].take(3).toList();
  }

  final summary = json['summary'];

  return PracticeSummary.fromEvaluation(
    score: score('overall_score'),
    skills: {
      PracticeSkill.clarity: score('clarity'),
      PracticeSkill.empathy: score('empathy'),
      PracticeSkill.directness: score('directness'),
      PracticeSkill.confidence: score('confidence'),
    },
    summary: summary is String ? summary : '',
    strengths: notes('strengths'),
    improvements: notes('improvements'),
    usedAi: true,
  );
}

typedef CoachFallbackCallback =
    void Function(Object error, StackTrace stackTrace, String operation);

class ResilientCoachService implements CoachService {
  const ResilientCoachService({
    required this.primary,
    required this.fallback,
    this.onFallback,
  });

  final CoachService primary;
  final CoachService fallback;

  /// Called when the primary fails and the offline coach takes over.
  final CoachFallbackCallback? onFallback;

  @override
  bool get isAiEnabled => primary.isAiEnabled;

  @override
  Future<EmployeeReply> respond({
    required Scenario scenario,
    required SimulationDifficulty difficulty,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String managerResponse,
  }) async {
    try {
      return await primary.respond(
        scenario: scenario,
        difficulty: difficulty,
        turnIndex: turnIndex,
        history: history,
        managerResponse: managerResponse,
      );
    } on Object catch (error, stackTrace) {
      onFallback?.call(error, stackTrace, 'respond');
      return fallback.respond(
        scenario: scenario,
        difficulty: difficulty,
        turnIndex: turnIndex,
        history: history,
        managerResponse: managerResponse,
      );
    }
  }

  @override
  Future<PracticeSummary> evaluate({
    required Scenario scenario,
    required List<PracticeResponse> history,
  }) async {
    try {
      return await primary.evaluate(scenario: scenario, history: history);
    } on Object catch (error, stackTrace) {
      onFallback?.call(error, stackTrace, 'evaluate');
      return fallback.evaluate(scenario: scenario, history: history);
    }
  }
}

/// The on-device coach. Keeps the app usable with no key and no network, and
/// is what every remote failure degrades to.
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
  Future<EmployeeReply> respond({
    required Scenario scenario,
    required SimulationDifficulty difficulty,
    required int turnIndex,
    required List<PracticeResponse> history,
    required String managerResponse,
  }) async {
    final next = turnIndex + 1;
    return EmployeeReply(
      // Mid-conversation lines are authored, so the offline coach cannot
      // vary how hard the pushback is. How the conversation *lands* it can:
      // a very defensive person does not close by agreeing.
      text: next < scenario.turns.length
          ? scenario.turns[next].employeeLine
          : _closingFor(difficulty),
      source: EvaluationSource.offline,
    );
  }

  static String _closingFor(SimulationDifficulty difficulty) =>
      switch (difficulty) {
        SimulationDifficulty.calm =>
          'Okay. I understand what we’re agreeing to.',
        SimulationDifficulty.defensive =>
          'Fine. I hear you, though I still think some of this wasn’t on me.',
        SimulationDifficulty.veryDefensive =>
          'Sure. I’ll do what you’re asking. I don’t agree with it.',
      };

  @override
  Future<PracticeSummary> evaluate({
    required Scenario scenario,
    required List<PracticeResponse> history,
  }) async {
    final scored = [
      for (var index = 0; index < history.length; index++)
        (index, _scoreTurn(scenario, index, history[index].text)),
    ];

    int dimension(int Function(_TurnScore) read) {
      if (scored.isEmpty) return 50;
      final total = scored.fold<int>(0, (sum, item) => sum + read(item.$2));
      return (50 + (total / scored.length) * 20).round().clamp(0, 100);
    }

    final ranked = [...scored]
      ..sort((a, b) => b.$2.total.compareTo(a.$2.total));

    return PracticeSummary.fromEvaluation(
      score: dimension((score) => score.total ~/ 4),
      skills: {
        PracticeSkill.clarity: dimension((score) => score.clarity),
        PracticeSkill.empathy: dimension((score) => score.empathy),
        PracticeSkill.directness: dimension((score) => score.directness),
        PracticeSkill.confidence: dimension((score) => score.confidence),
      },
      summary: '',
      strengths: ranked.isEmpty
          ? const []
          : [_noteFor(scenario, history, ranked.first.$1, strength: true)],
      improvements: ranked.length < 2
          ? const []
          : [_noteFor(scenario, history, ranked.last.$1, strength: false)],
      usedAi: false,
    );
  }

  /// The quote is whatever the manager actually typed; the suggestion is the
  /// strongest authored wording for that turn, so even with no network the
  /// report can still say "try this instead" and mean it.
  CoachingNote _noteFor(
    Scenario scenario,
    List<PracticeResponse> history,
    int turnIndex, {
    required bool strength,
  }) {
    final score = _scoreTurn(scenario, turnIndex, history[turnIndex].text);
    final best = turnIndex < scenario.turns.length
        ? scenario.turns[turnIndex].choices.reduce(
            (a, b) => a.scoreDelta >= b.scoreDelta ? a : b,
          )
        : null;

    return CoachingNote(
      turnIndex: turnIndex,
      quote: history[turnIndex].text,
      comment: strength ? _praiseFor(score) : _critiqueFor(score),
      suggestion: strength ? null : best?.text,
    );
  }

  _TurnScore _scoreTurn(Scenario scenario, int turnIndex, String text) {
    final lower = text.toLowerCase();

    // If the manager landed close to an authored choice, borrow its scoring:
    // the authored content is better judgement than any keyword list.
    if (turnIndex < scenario.turns.length) {
      final (choice, similarity) = _closestChoice(
        scenario.turns[turnIndex].choices,
        text,
      );
      if (similarity >= 0.2) {
        return _TurnScore(
          clarity: choice.clarity,
          empathy: choice.empathy,
          directness: choice.directness,
          confidence: choice.confidence,
        );
      }
    }

    return _TurnScore(
      clarity: _signalScore(lower, const [
        'need',
        'expect',
        'agree',
        'deadline',
        'impact',
        'next step',
        'by ',
      ]),
      empathy: _signalScore(lower, const [
        'understand',
        'hear',
        'see',
        'appreciate',
        'sorry',
        'help',
      ]),
      directness: _signalScore(lower, const [
        'need',
        'cannot',
        'can’t',
        'will not',
        'expect',
        'impact',
        'tradeoff',
      ]),
      confidence: _hedgeScore(lower),
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

  Set<String> _tokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9’]+'))
      .where((word) => word.length > 1 && !_stopWords.contains(word))
      .toSet();

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

  String _praiseFor(_TurnScore score) {
    if (score.empathy >= 1 && score.directness >= 1) {
      return 'This held the expectation and the relationship at the same time, which is the hard part.';
    }
    if (score.directness >= 1) {
      return 'You named the issue instead of circling it.';
    }
    if (score.empathy >= 1) {
      return 'You made room for their side before pressing on.';
    }
    return 'You stayed in the conversation rather than backing out of it.';
  }

  String _critiqueFor(_TurnScore score) {
    if (score.confidence < 0) {
      return 'The hedging here invites a negotiation you did not mean to open.';
    }
    if (score.clarity < 1) {
      return 'The intent is right, but the specific issue and the next step are left for them to guess.';
    }
    if (score.empathy < 1) {
      return 'Clear, but nothing here shows you heard the pressure they are under.';
    }
    return 'Warm and clear, and the expectation is still soft enough to be missed.';
  }
}

class _TurnScore {
  const _TurnScore({
    required this.clarity,
    required this.empathy,
    required this.directness,
    required this.confidence,
  });

  final int clarity;
  final int empathy;
  final int directness;
  final int confidence;

  int get total => clarity + empathy + directness + confidence;
}

class CoachServiceException implements Exception {
  const CoachServiceException(this.message);

  final String message;

  @override
  String toString() => 'CoachServiceException: $message';
}
