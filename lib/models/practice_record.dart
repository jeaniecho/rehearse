import 'practice_response.dart';
import 'practice_summary.dart';
import 'session_outcome.dart';

/// One finished rehearsal, kept on the device so progress survives restarts.
///
/// **A guided rehearsal carries no score.** Guided mode hands you three
/// written answers and tells you which one landed; what that measures is
/// recognition, not what you would have said, so counting it as a score
/// would put a number on the wrong thing and average it in with the
/// free-form rehearsals that do measure it. The session is still kept —
/// it is practice, it holds the streak, it appears in the history — with
/// every dimension left null.
///
/// The rule lives in [fromSummary] and [tryFromJson], the two doors a record
/// comes through. The constructor stays the raw shape so a test can build
/// whatever it needs to.
class PracticeRecord {
  const PracticeRecord({
    required this.scenarioId,
    required this.completedAt,
    required this.mode,
    required this.usedAi,
    this.score,
    this.clarity,
    this.empathy,
    this.directness,
    this.confidence,
    this.outcome,
  });

  factory PracticeRecord.fromSummary({
    required String scenarioId,
    required DateTime completedAt,
    required PracticeMode mode,
    required PracticeSummary summary,
  }) {
    final scored = mode != PracticeMode.guided;

    return PracticeRecord(
      scenarioId: scenarioId,
      completedAt: completedAt,
      mode: mode,
      score: scored ? summary.score : null,
      clarity: scored ? summary.clarity : null,
      empathy: scored ? summary.empathy : null,
      directness: scored ? summary.directness : null,
      confidence: scored ? summary.confidence : null,
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

    final mode = json['mode'] == PracticeMode.freestyle.name
        ? PracticeMode.freestyle
        : PracticeMode.guided;

    // Guided records written before guided stopped being scored still carry
    // their numbers. They are dropped on the way in rather than migrated
    // away, so there is one rule — a guided rehearsal has no score — and no
    // date on which history changes meaning.
    //
    // Keyed on the stored word, not on [mode], which reads anything that is
    // not "freestyle" as guided: a record written before the field existed
    // would otherwise have a real score deleted on the strength of a
    // default.
    final wasGuided = json['mode'] == PracticeMode.guided.name;

    int? score(String key) {
      if (wasGuided) return null;
      final value = json[key];
      return value is num ? value.round().clamp(0, 100) : null;
    }

    return PracticeRecord(
      scenarioId: scenarioId,
      completedAt: completedAt,
      mode: mode,
      score: score('score'),
      clarity: score('clarity'),
      empathy: score('empathy'),
      // Records written before the rubric gained a fourth dimension stored
      // this as `courage`, which was always described as directness.
      directness: json.containsKey('directness')
          ? score('directness')
          : score('courage'),
      // Genuinely absent from older records rather than neutral, so it is
      // left out of averages instead of dragging them toward 50.
      confidence: score('confidence'),
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

  /// Null on a guided rehearsal, which is not scored — see the class note.
  final int? score;
  final int? clarity;
  final int? empathy;
  final int? directness;

  /// Also null on records written before the rubric gained this dimension.
  final int? confidence;

  /// Null on records written before the report gained an outcome (PRD §11).
  final SessionOutcome? outcome;
  final bool usedAi;

  Map<String, dynamic> toJson() => {
    'scenarioId': scenarioId,
    'completedAt': completedAt.toIso8601String(),
    'mode': mode.name,
    'score': ?score,
    'clarity': ?clarity,
    'empathy': ?empathy,
    'directness': ?directness,
    'confidence': ?confidence,
    'outcome': ?outcome?.name,
    'usedAi': usedAi,
  };
}
