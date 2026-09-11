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
  /// edge, a short falloff for the weight.
  ///
  /// Tuned against the marks rather than against Material. A 12px blur four
  /// points down is a card *hovering*; the illustrations do not hover, they
  /// rest — their style block asks for "one soft contact shadow beneath",
  /// which is tight and close. Matching them is the whole point of lending
  /// this to a card, and the old values were lent from elevation instead.
  ///
  /// Warm, too. Pure black under a warm palette is the tell of a default
  /// theme: it makes white surfaces read blue-grey where they meet the
  /// page. This is [AppColors.charcoal], the ink the app already presses
  /// its buttons in.
  ///
  /// `AppTheme.cardTheme` carries the same weight through `elevation`,
  /// because `Card` takes an elevation rather than a shadow list. If one
  /// moves, move the other.
  static const lift = <BoxShadow>[
    BoxShadow(color: Color(0x14332E29), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14332E29), blurRadius: 5, offset: Offset(0, 2)),
  ];
}
