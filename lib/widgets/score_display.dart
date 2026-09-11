import 'package:flutter/material.dart';

import '../models/practice_summary.dart';
import '../theme/app_theme.dart';

/// The large circular conversation score used on the coaching report.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    required this.score,
    super.key,
    this.caption = 'CONVERSATION SCORE',
    this.diameter = 142,
    this.valueColor = AppColors.ink,
    this.captionColor = AppColors.muted,
    this.trackColor = AppColors.border,
  });

  final int score;
  final String caption;
  final double diameter;
  final Color valueColor;
  final Color captionColor;
  final Color trackColor;

  /// The ring is a fixed graphic, so unbounded text scaling would push the
  /// numerals straight out of the circle. Grow the whole ring with the text
  /// instead, and cap both together.
  static const _maxTextScale = 1.4;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final factor = (scaler.scale(100) / 100).clamp(1.0, _maxTextScale);
    final size = diameter * factor;

    return Center(
      child: Semantics(
        label: '$caption: $score out of 100',
        excludeSemantics: true,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxTextScale,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: diameter * 0.077,
                    strokeCap: StrokeCap.round,
                    // Green, because the arc is progress and the palette
                    // reserves green for that. Rust read as a warning on a
                    // good score, and on the forest card it sat red against
                    // green.
                    color: AppColors.forest,
                    backgroundColor: trackColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: valueColor,
                        fontSize: diameter * 0.324,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled 0-100 bar for one of the four conversation skills.
///
/// Colour ranks rather than labels. Four dimensions in four hues said
/// nothing — clarity is not red — and one hue for all four said nothing
/// either. Green marks the skill carrying you, amber the one to work on,
/// and the two in between stay ink, so the chart makes the same claim the
/// sentence above it makes. See [SkillBars], which decides.
///
/// The three are the illustration palette exactly: deep green, charcoal and
/// muted amber (`docs/ILLUSTRATIONS.md` §1). The chart is drawn in the same
/// colours as the art beside it.
class SkillBar extends StatelessWidget {
  const SkillBar({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value out of 100',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

/// The skill that alone scores [value], or null when it is shared.
///
/// The extremes are a claim about the numbers, so they may only name a skill
/// the numbers actually single out. Reducing to the first of a tie once
/// announced "Clarity is carrying you" off three dimensions level at 43 — a
/// winner the numbers do not have.
PracticeSkill? soleHolder(Map<PracticeSkill, int> skills, int value) {
  final holders = skills.entries.where((entry) => entry.value == value);
  return holders.length == 1 ? holders.first.key : null;
}

/// The strongest and the weakest skill in [skills], each null where the
/// extreme is shared or where every skill is level.
({PracticeSkill? strongest, PracticeSkill? weakest}) skillExtremes(
  Map<PracticeSkill, int> skills,
) {
  final best = skills.values.reduce((a, b) => a >= b ? a : b);
  final worst = skills.values.reduce((a, b) => a <= b ? a : b);
  if (best == worst) return (strongest: null, weakest: null);
  return (
    strongest: soleHolder(skills, best),
    weakest: soleHolder(skills, worst),
  );
}

/// Every skill in a summary or a history average, drawn in report order.
///
/// The two extremes are coloured and the rest are ink. Both the chart and
/// the sentence a caller writes above it go through [skillExtremes], so
/// they cannot disagree about which skill is carrying you.
class SkillBars extends StatelessWidget {
  const SkillBars({required this.values, super.key, this.spacing = 16});

  final Map<PracticeSkill, int> values;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList();
    final (:strongest, :weakest) = skillExtremes(values);

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          SkillBar(
            label: entries[index].key.label,
            value: entries[index].value,
            color: switch (entries[index].key) {
              final skill when skill == strongest => AppColors.forest,
              final skill when skill == weakest => AppColors.amber,
              // Charcoal, not ink: the warm neutral the marks are cut in,
              // and the lightest warm grey that still clears 3:1 on the
              // track is barely lighter than this anyway.
              _ => AppColors.charcoal,
            },
          ),
          if (index != entries.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}
