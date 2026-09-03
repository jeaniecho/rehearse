import 'practice_response.dart';

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
    required this.courage,
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
      courage: dimension((response) => response.courage),
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
  final int courage;
  final bool usedAi;

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
