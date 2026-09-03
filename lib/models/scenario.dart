import 'package:flutter/material.dart';

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
  });

  final String text;
  final int scoreDelta;
  final String feedback;
  final int clarity;
  final int empathy;
  final int directness;
  final int confidence;
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
