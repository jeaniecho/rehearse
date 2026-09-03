import 'practice_response.dart';
import 'practice_summary.dart';

/// One finished rehearsal, kept on the device so progress survives restarts.
class PracticeRecord {
  const PracticeRecord({
    required this.scenarioId,
    required this.completedAt,
    required this.mode,
    required this.score,
    required this.clarity,
    required this.empathy,
    required this.courage,
    required this.usedAi,
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
      courage: summary.courage,
      usedAi: summary.usedAi,
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
      courage: score('courage', 50),
      usedAi: json['usedAi'] == true,
    );
  }

  final String scenarioId;
  final DateTime completedAt;
  final PracticeMode mode;
  final int score;
  final int clarity;
  final int empathy;
  final int courage;
  final bool usedAi;

  Map<String, dynamic> toJson() => {
    'scenarioId': scenarioId,
    'completedAt': completedAt.toIso8601String(),
    'mode': mode.name,
    'score': score,
    'clarity': clarity,
    'empathy': empathy,
    'courage': courage,
    'usedAi': usedAi,
  };
}
