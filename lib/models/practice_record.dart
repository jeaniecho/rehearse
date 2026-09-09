import 'practice_response.dart';
import 'practice_summary.dart';
import 'session_outcome.dart';

/// One finished rehearsal, kept on the device so progress survives restarts.
class PracticeRecord {
  const PracticeRecord({
    required this.scenarioId,
    required this.completedAt,
    required this.mode,
    required this.score,
    required this.clarity,
    required this.empathy,
    required this.directness,
    required this.usedAi,
    this.confidence,
    this.outcome,
  });

  factory PracticeRecord.fromSummary({
    required String scenarioId,
    required DateTime completedAt,
    required PracticeMode mode,
    required PracticeSummary summary,
  }) {
    return PracticeRecord(
      scenarioId: scenarioId,
      completedAt: completedAt,
      mode: mode,
      score: summary.score,
      clarity: summary.clarity,
      empathy: summary.empathy,
      directness: summary.directness,
      confidence: summary.confidence,
      usedAi: summary.usedAi,
      outcome: summary.outcome,
    );
  }

  /// Returns null rather than throwing, so one corrupt entry written by an
  /// older build cannot wipe out the rest of someone's history.
  static PracticeRecord? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final scenarioId = json['scenarioId'];
    final completedAt = DateTime.tryParse('${json['completedAt']}');
    if (scenarioId is! String || scenarioId.isEmpty || completedAt == null) {
      return null;
    }

    int score(String key, int fallback) {
      final value = json[key];
      return value is num ? value.round().clamp(0, 100) : fallback;
    }

    return PracticeRecord(
      scenarioId: scenarioId,
      completedAt: completedAt,
      mode: json['mode'] == PracticeMode.freestyle.name
          ? PracticeMode.freestyle
          : PracticeMode.guided,
      score: score('score', 50),
      clarity: score('clarity', 50),
      empathy: score('empathy', 50),
      // Records written before the rubric gained a fourth dimension stored
      // this as `courage`, which was always described as directness.
      directness: json.containsKey('directness')
          ? score('directness', 50)
          : score('courage', 50),
      // Genuinely absent from those records rather than neutral, so it is
      // left out of averages instead of dragging them toward 50.
      confidence: json['confidence'] is num ? score('confidence', 50) : null,
      // Absent on records written before the report gained an outcome. Left
      // null rather than guessed: nothing measured how those ended.
      outcome: json['outcome'] is String
          ? SessionOutcomeLabel.fromName(
              json['outcome'],
              or: SessionOutcome.unresolved,
            )
          : null,
      usedAi: json['usedAi'] == true,
    );
  }

  final String scenarioId;
  final DateTime completedAt;
  final PracticeMode mode;
  final int score;
  final int clarity;
  final int empathy;
  final int directness;

  /// Null on records written before the rubric gained this dimension.
  final int? confidence;

  /// Null on records written before the report gained an outcome (PRD §11).
  final SessionOutcome? outcome;
  final bool usedAi;

  Map<String, dynamic> toJson() => {
    'scenarioId': scenarioId,
    'completedAt': completedAt.toIso8601String(),
    'mode': mode.name,
    'score': score,
    'clarity': clarity,
    'empathy': empathy,
    'directness': directness,
    'confidence': ?confidence,
    'outcome': ?outcome?.name,
    'usedAi': usedAi,
  };
}
