import 'package:flutter/material.dart';

/// The paper vocabulary the illustrations are made of, borrowed by the UI.
///
/// Deliberately two things and not three. The marks read as paper because of
/// **edge and shadow**, not mainly because of grain — so [lift] is the part
/// that goes everywhere and [grain] is the part that does not.
///
/// `AppColors.canvas` records why: an off-white ground "was most of what made
/// the app read as generated". A grain field over the whole app is the same
/// mistake with more texture. Two further reasons to keep it off white
/// surfaces, both in `docs/STATUS.md` §6 — three palette pairs already fail
/// WCAG AA for body text, and a grain field has no contrast ratio to state;
/// and there is no dark theme yet, where this would need a different stock.
abstract final class Paper {
  static const _stock = AssetImage('assets/texture/stock.png');

  /// Grain for a **coloured block** — a filled card carrying a heading and
  /// a line or two, never body copy on white.
  static const grain = DecorationImage(
    image: _stock,
    repeat: ImageRepeat.repeat,
    // The asset is already faint; this is the dial worth turning.
    opacity: 0.55,
  );

  /// The same stock on a dark ground, turned most of the way up.
  ///
  /// Not a brightness fix but a polarity one: the grain carries light and
  /// dark specks, and on forest the dark half does nothing at all. Only the
  /// light specks are left to do the work, so they have to do more of it.
  static const grainOnDark = DecorationImage(
    image: _stock,
    repeat: ImageRepeat.repeat,
    opacity: 0.9,
  );

  /// A contact shadow, not a drop shadow.
  ///
  /// The style block gives every mark "one soft contact shadow beneath". A
  /// card with only a hairline border reads as drawn *on* the page; this
  /// reads as laid on it. Two stops: a tight one for the edge, a wider one
  /// for the weight.
  static const lift = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}
