import 'package:flutter/material.dart';

/// The one thing the UI borrows from the illustrations.
///
/// A card separated only by a hairline border reads as drawn *on* the page.
/// The marks in `assets/illustrations` read as paper because of edge and
/// shadow — the style block gives every one of them "one soft contact shadow
/// beneath" — and [lift] is that, lent to a card so it reads as laid on the
/// page instead.
///
/// **A grain texture was prototyped here and dropped.** Recorded so it is
/// not proposed again. It was tiled on the three coloured blocks — the
/// briefing's person card, the progress streak banner, home's card for what
/// is next — and it worked, in the narrow sense that it looked like paper.
/// It went because the app does not need it: shadow alone carries the
/// material, and grain buys atmosphere at the cost of a surface that can no
/// longer state a contrast ratio. Three palette pairs already fail WCAG AA
/// for body text (`docs/STATUS.md` §6), there is no dark theme yet — dark
/// stock is a different material, not this one tinted — and `AppColors
/// .canvas` records that an off-white ground "was most of what made the app
/// read as generated". The wide version of the idea is worse still: the
/// marks read as objects because the page behind them is plain.
///
/// `4fa35fc` has the implementation if it is ever wanted back.
abstract final class Paper {
  /// A contact shadow, not a drop shadow. Two stops: a tight one for the
  /// edge, a wider one for the weight.
  ///
  /// `AppTheme.cardTheme` carries the same weight through `elevation`,
  /// because `Card` takes an elevation rather than a shadow list. If one
  /// moves, move the other.
  static const lift = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}
