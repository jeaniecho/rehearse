/// One specific observation about something the manager actually said.
///
/// The quote is the point. PRD §5.4: "You could improve your communication"
/// is worthless next to "you said X, which leaves the expectation unclear —
/// try Y". Everything here exists to make that sentence possible.
class CoachingNote {
  const CoachingNote({
    required this.turnIndex,
    required this.quote,
    required this.comment,
    this.suggestion,
  });

  /// Which manager turn this refers to, so the report can point at it.
  final int turnIndex;

  /// The manager's own words, verbatim. Never paraphrased — a critique of
  /// something you did not say is worse than no critique.
  final String quote;

  /// Why it worked, or why it did not.
  final String comment;

  /// Stronger wording. Only on improvements; a strength needs no rewrite.
  final String? suggestion;

  static CoachingNote? tryFromJson(Object? json, {required int turnCount}) {
    if (json is! Map<String, dynamic>) return null;

    final quote = json['quote'];
    final comment = json['comment'];
    if (quote is! String || quote.trim().isEmpty) return null;
    if (comment is! String || comment.trim().isEmpty) return null;

    final turnIndex = json['turn_index'];
    final suggestion = json['suggestion'];

    return CoachingNote(
      turnIndex: turnIndex is num
          ? turnIndex.round().clamp(0, turnCount - 1)
          : 0,
      quote: quote.trim(),
      comment: comment.trim(),
      suggestion: suggestion is String && suggestion.trim().isNotEmpty
          ? suggestion.trim()
          : null,
    );
  }

  /// Whether [quote] is really something the manager said.
  ///
  /// Models paraphrase, and a fabricated quote is the one failure mode that
  /// would make the whole report untrustworthy, so anything that cannot be
  /// found in the transcript is dropped rather than shown.
  bool isGroundedIn(List<String> managerTurns) {
    final needle = _normalize(quote);
    if (needle.isEmpty) return false;
    return managerTurns.any((turn) => _normalize(turn).contains(needle));
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[‘’]'), "'")
      .replaceAll(RegExp('[“”]'), '"')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
