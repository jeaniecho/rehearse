/// How the conversation ended (PRD §9), shown on the report because §11
/// lists it under `Required:`.
///
/// Not a score band. A conversation can be handled well and still end
/// unresolved, which is the point the PRD is making — "the product should
/// not require perfect resolution". Deriving this from [PracticeSummary.score]
/// would make the report claim the simulation modelled something it did not,
/// so every value here traces to authored content or to the coach's own
/// judgement of the transcript.
enum SessionOutcome { success, partial, unresolved, escalated }

extension SessionOutcomeLabel on SessionOutcome {
  String get label => switch (this) {
    SessionOutcome.success => 'Resolved',
    SessionOutcome.partial => 'Partly resolved',
    SessionOutcome.unresolved => 'Unresolved',
    SessionOutcome.escalated => 'Escalated',
  };

  /// One line on what that meant for the other person, in the manager's
  /// terms rather than the rubric's.
  String get description => switch (this) {
    SessionOutcome.success =>
      'They accepted the expectation and you left with an agreement.',
    SessionOutcome.partial => 'They heard you, but part of it is still open.',
    SessionOutcome.unresolved =>
      'The conversation ended without landing the expectation.',
    SessionOutcome.escalated =>
      'It got worse than when you started. This one would need a follow-up.',
  };

  /// Takes [Object?] rather than a string: a coach that answers with a
  /// number should cost the outcome, not the whole evaluation.
  static SessionOutcome fromName(Object? name, {required SessionOutcome or}) {
    for (final value in SessionOutcome.values) {
      if (value.name == name) return value;
    }
    return or;
  }
}

/// Where the simulation thinks the conversation stands after a turn.
///
/// This is the mechanism behind PRD §9's first three end conditions — goal
/// reached, the other person accepts, or the conversation breaks down. The
/// fourth, running out of turns, needs no declaration.
///
/// It never reaches the person practising mid-conversation: PRD §7.3 says
/// the simulation must not explain itself while it runs, so this only ever
/// decides whether there is another turn.
enum SimulationResolution { continuing, resolved, breakdown }

extension SimulationResolutionParse on SimulationResolution {
  static SimulationResolution fromName(Object? name) {
    for (final value in SimulationResolution.values) {
      if (value.name == name) return value;
    }
    return SimulationResolution.continuing;
  }
}
