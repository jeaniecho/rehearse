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
  });

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
    );
  }

  static const _startingScore = 50;
  static const _dimensionWeight = 8;

  final int score;
  final int clarity;
  final int empathy;
  final int directness;
  final int confidence;
  final bool usedAi;

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

  String get summary => switch (score) {
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
