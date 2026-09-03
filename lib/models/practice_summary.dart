import 'coaching_note.dart';
import 'practice_response.dart';

/// The four things a hard message needs to land (PRD §10).
enum PracticeSkill { clarity, empathy, directness, confidence }

extension PracticeSkillLabel on PracticeSkill {
  String get label => switch (this) {
    PracticeSkill.clarity => 'Clarity',
    PracticeSkill.empathy => 'Empathy',
    PracticeSkill.directness => 'Directness',
    PracticeSkill.confidence => 'Confidence',
  };

  /// What this skill running low actually looks like in a conversation.
  /// Used to make coaching and the paywall specific to the person reading.
  String get weaknessDescription => switch (this) {
    PracticeSkill.clarity =>
      'You tend to leave the expectation vague once the conversation gets uncomfortable.',
    PracticeSkill.empathy =>
      'You get to the point, but the other person rarely feels heard first.',
    PracticeSkill.directness =>
      'You tend to soften the expectation when the other person pushes back.',
    PracticeSkill.confidence =>
      'You start well, then give ground the moment the other person leans on you.',
  };
}

/// The scored outcome of one completed rehearsal.
///
/// A conversation starts at a neutral 50 and each turn moves the running
/// score. Skill dimensions move on the same 0-100 scale so a report and a
/// history entry always agree on the numbers.
class PracticeSummary {
  const PracticeSummary({
    required this.score,
    required this.clarity,
    required this.empathy,
    required this.directness,
    required this.confidence,
    required this.usedAi,
    this.coachSummary,
    this.strengths = const [],
    this.improvements = const [],
  });

  /// A conversation the coach scored as a whole, at the end.
  ///
  /// The dimensions here are absolute 0-100 judgements of the finished
  /// transcript rather than a running total, which is the point of asking
  /// once at the end instead of turn by turn.
  factory PracticeSummary.fromEvaluation({
    required int score,
    required Map<PracticeSkill, int> skills,
    required String summary,
    required List<CoachingNote> strengths,
    required List<CoachingNote> improvements,
    required bool usedAi,
  }) {
    int skill(PracticeSkill key) => (skills[key] ?? 50).clamp(0, 100);

    return PracticeSummary(
      score: score.clamp(0, 100),
      clarity: skill(PracticeSkill.clarity),
      empathy: skill(PracticeSkill.empathy),
      directness: skill(PracticeSkill.directness),
      confidence: skill(PracticeSkill.confidence),
      usedAi: usedAi,
      coachSummary: summary.trim().isEmpty ? null : summary.trim(),
      strengths: strengths,
      improvements: improvements,
    );
  }

  factory PracticeSummary.fromResponses(List<PracticeResponse> responses) {
    int dimension(int Function(PracticeResponse) read) {
      final total = responses.fold<int>(
        _startingScore,
        (sum, item) => sum + read(item) * _dimensionWeight,
      );
      return total.clamp(0, 100);
    }

    final score = responses
        .fold<int>(_startingScore, (sum, item) => sum + item.scoreDelta)
        .clamp(0, 100);

    return PracticeSummary(
      score: score,
      clarity: dimension((response) => response.clarity),
      empathy: dimension((response) => response.empathy),
      directness: dimension((response) => response.directness),
      confidence: dimension((response) => response.confidence),
      usedAi: responses.any(
        (response) => response.source == EvaluationSource.ai,
      ),
      // Authored feedback is already turn-by-turn and already quotes the
      // manager, because in guided mode the manager picked the words.
      strengths: _notesFrom(responses, keep: (delta) => delta >= 8),
      improvements: _notesFrom(responses, keep: (delta) => delta < 8),
    );
  }

  static List<CoachingNote> _notesFrom(
    List<PracticeResponse> responses, {
    required bool Function(int scoreDelta) keep,
  }) {
    final notes = [
      for (var index = 0; index < responses.length; index++)
        if (keep(responses[index].scoreDelta))
          CoachingNote(
            turnIndex: index,
            quote: responses[index].text,
            comment: responses[index].feedback,
            suggestion: responses[index].suggestion,
          ),
    ]..sort((a, b) => a.turnIndex.compareTo(b.turnIndex));

    // Three is the PRD's cap and about as much as anyone acts on.
    return notes.length <= 3 ? notes : notes.sublist(0, 3);
  }

  static const _startingScore = 50;
  static const _dimensionWeight = 8;

  final int score;
  final int clarity;
  final int empathy;
  final int directness;
  final int confidence;
  final bool usedAi;

  /// The coach's prose read of the whole conversation. Null when nothing
  /// scored it as a whole, in which case [summary] falls back to the band.
  final String? coachSummary;
  final List<CoachingNote> strengths;
  final List<CoachingNote> improvements;

  /// Every dimension, in the order the report and the progress screen show
  /// them, so the two cannot fall out of step.
  Map<PracticeSkill, int> get skills => {
    PracticeSkill.clarity: clarity,
    PracticeSkill.empathy: empathy,
    PracticeSkill.directness: directness,
    PracticeSkill.confidence: confidence,
  };

  String get headline => switch (score) {
    >= 82 => 'You held the line with care.',
    >= 68 => 'A solid conversation—with room to sharpen.',
    >= 52 => 'You stayed in it. That’s where growth starts.',
    _ => 'That was hard. Let’s make the next one clearer.',
  };

  String get summary => coachSummary ?? bandSummary;

  String get bandSummary => switch (score) {
    >= 82 =>
      'You balanced candor with curiosity and ended on a concrete agreement.',
    >= 68 =>
      'Your intent was clear. A little more specificity would make the outcome easier to act on.',
    >= 52 =>
      'You protected the relationship, but softened key moments where clarity mattered.',
    _ =>
      'You reacted to the pressure instead of naming the issue. A slower opening can change the whole conversation.',
  };
}
