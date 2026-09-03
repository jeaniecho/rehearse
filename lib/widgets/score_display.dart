import 'package:flutter/material.dart';

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

  /// The same ring drawn to sit on a dark surface.
  const ScoreRing.onDark({
    required this.score,
    super.key,
    this.caption = 'CONVERSATION SCORE',
    this.diameter = 142,
  }) : valueColor = Colors.white,
       captionColor = const Color(0xFFD9E5DD),
       trackColor = const Color(0x33FFFFFF);

  final int score;
  final String caption;
  final double diameter;
  final Color valueColor;
  final Color captionColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: '$caption: $score out of 100',
        excludeSemantics: true,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: diameter * 0.077,
                  strokeCap: StrokeCap.round,
                  color: AppColors.coral,
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
                      fontWeight: FontWeight.w900,
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
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled 0-100 bar for one of the three conversation skills.
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
                  fontWeight: FontWeight.w900,
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

/// The colour each conversation skill is drawn in, so the report and the
/// progress screen stay consistent.
abstract final class SkillColors {
  static const clarity = AppColors.coral;
  static const empathy = AppColors.forest;
  static const courage = Color(0xFF7660A8);
}
