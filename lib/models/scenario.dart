import 'package:flutter/material.dart';

enum ScenarioDifficulty { warmUp, challenging, highStakes }

extension ScenarioDifficultyLabel on ScenarioDifficulty {
  String get label => switch (this) {
    ScenarioDifficulty.warmUp => 'Warm-up',
    ScenarioDifficulty.challenging => 'Challenging',
    ScenarioDifficulty.highStakes => 'High stakes',
  };
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
    required this.difficulty,
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
  final ScenarioDifficulty difficulty;
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
