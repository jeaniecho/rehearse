import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The small all-caps label: the kicker above a screen title, and the label
/// on a card.
///
/// There were eleven of these written out by hand, all at 800 weight but
/// across three sizes and six different letter-spacings — which is how a
/// thing that is meant to read as one element stops doing so. Two sizes are
/// real: the screen kicker, and the smaller one inside a card.
///
/// `SCORE` on the coaching report is deliberately not one of these. It is
/// tracked much wider because it sits under a 64pt numeral, and folding it
/// in here would flatten a difference that was chosen.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {this.color = AppColors.coral, super.key})
    : _fontSize = 10,
      _letterSpacing = 0.8;

  /// The version that labels something inside a card rather than a screen.
  const Eyebrow.small(this.text, {this.color = AppColors.coral, super.key})
    : _fontSize = 9,
      _letterSpacing = 0.8;

  final String text;
  final Color color;
  final double _fontSize;
  final double _letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: _fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: _letterSpacing,
      ),
    );
  }
}
