import 'package:flutter/material.dart';

import 'session_outcome.dart';

/// How much the situation itself is carrying — a property of the scenario,
/// fixed by whoever wrote it.
///
/// Distinct from [SimulationDifficulty], which is how hard the other person
/// pushes back and is chosen per session. A high-stakes conversation can be
/// held with someone calm; a warm-up can be held with someone furious.
enum ScenarioStakes { warmUp, challenging, highStakes }

extension ScenarioStakesLabel on ScenarioStakes {
  String get label => switch (this) {
    ScenarioStakes.warmUp => 'Warm-up',
    ScenarioStakes.challenging => 'Challenging',
    ScenarioStakes.highStakes => 'High stakes',
  };
}

/// How hard the other person pushes back, chosen before each rehearsal
/// (PRD §7.2). Not cosmetic: it reaches the simulation prompt and changes
/// how readily the conversation moves.
enum SimulationDifficulty { calm, defensive, veryDefensive }

extension SimulationDifficultyLabel on SimulationDifficulty {
  String get label => switch (this) {
    SimulationDifficulty.calm => 'Calm',
    SimulationDifficulty.defensive => 'Defensive',
    SimulationDifficulty.veryDefensive => 'Very defensive',
  };

  /// What picking this actually buys you, in the manager's terms.
  String get description => switch (this) {
    SimulationDifficulty.calm => 'Hears you out. Good for finding your words.',
    SimulationDifficulty.defensive =>
      'Pushes back and needs convincing. The realistic middle.',
    SimulationDifficulty.veryDefensive =>
      'Takes it personally and gives no ground easily.',
  };

  static SimulationDifficulty fromName(String? name) {
    for (final value in SimulationDifficulty.values) {
      if (value.name == name) return value;
    }
    return SimulationDifficulty.defensive;
  }
}

class ResponseChoice {
  const ResponseChoice({
    required this.text,
    required this.scoreDelta,
    required this.feedback,
    required this.clarity,
    required this.empathy,
    required this.directness,
    required this.confidence,
    this.resolution,
  });

  final String text;
  final int scoreDelta;
  final String feedback;
  final int clarity;
  final int empathy;
  final int directness;
  final int confidence;

  /// How the conversation lands if this is the manager's closing line.
  ///
  /// Authored on the last turn of every scenario and nowhere else, which is
  /// what `scenarios_test.dart` enforces. Guided replies cannot end early —
  /// the authored turns always run out — so the closing move is the only
  /// thing that decides the outcome, and it is the thing the other person
  /// actually walks away with.
  final SessionOutcome? resolution;
}

class DialogueTurn {
  const DialogueTurn({
    required this.employeeLine,
    required this.prompt,
    required this.choices,
  });

  final String employeeLine;
  final String prompt;
  final List<ResponseChoice> choices;
}

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.skill,
    required this.durationMinutes,
    required this.stakes,
    required this.icon,
    required this.tint,
    required this.personName,
    required this.personRole,
    required this.personInitials,
    required this.context,
    required this.goal,
    required this.watchFor,
    required this.openingLine,
    required this.turns,
  });

  final String id;
  final String title;
  final String subtitle;
  final String skill;
  final int durationMinutes;
  final ScenarioStakes stakes;

  /// The compact stand-in, used where a paper mark would be too small to
  /// read — the practice history rows. Everywhere the scenario is being
  /// chosen or briefed, `Illustration.scenario` looks up its mark by [id].
  final IconData icon;

  final Color tint;
  final String personName;
  final String personRole;
  final String personInitials;
  final String context;
  final String goal;
  final String watchFor;
  final String openingLine;
  final List<DialogueTurn> turns;
}
