import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A score, worn as a pill.
///
/// Two colours and one rule: at or above the good band it is [AppColors.mint]
/// with [AppColors.forest] on it, below it the well colour with charcoal.
/// A score under the band used to lose its pill and sit as a loose numeral,
/// which made a list half chips and half text.
///
/// Shared because it is the same object in two places — the corner of a
/// library tile and the end of a history row — and two copies of a rule
/// drift. [compact] is the tile's size; the row gets the larger one.
class ScoreChip extends StatelessWidget {
  const ScoreChip(this.score, {this.compact = false, super.key});

  /// The band the app calls good, and the only number in this file.
  static const goodBand = 68;

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strong = score >= goodBand;

    return Semantics(
      label: 'Scored $score out of 100',
      excludeSemantics: true,
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: strong ? AppColors.mint : AppColors.subtle,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$score',
          style: TextStyle(
            color: strong ? AppColors.forest : AppColors.charcoal,
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
