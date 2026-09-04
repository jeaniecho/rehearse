import 'package:flutter/material.dart';

/// A paper cut-out mark from `assets/illustrations`.
///
/// The set, its style, and the prompt behind every image are recorded in
/// `docs/ILLUSTRATIONS.md`. The bundled PNGs are derived — the 1254px
/// masters live in `art/` and never ship.
///
/// Every mark is decorative: it repeats something the adjacent text already
/// says, so it is kept out of the semantics tree rather than given a label
/// a screen reader would have to read twice.
class Illustration extends StatelessWidget {
  /// The mark for a scenario. Filenames are keyed by scenario id, which is
  /// why there is no lookup table and no field on the model to forget.
  const Illustration.scenario(this.name, {this.size = scenarioSize, super.key});

  const Illustration.emptyProgress({this.size = heroSize, super.key})
    : name = 'empty-progress';

  const Illustration.proUnlock({this.size = heroSize, super.key})
    : name = 'pro-unlock';

  /// The two bubbles, for [BrandMark]. Drawn rather than painted since the
  /// rest of the brand became paper — see `docs/ILLUSTRATIONS.md` §5.
  const Illustration.logo({this.size = logoSize, super.key}) : name = 'logo';

  final String name;
  final double size;

  /// The briefing, where a scenario mark labels a header.
  static const scenarioSize = 40.0;

  /// The home grid.
  static const tileSize = 56.0;

  /// The home card for whatever is next — the largest a scenario mark is
  /// drawn anywhere, and so the size they are all cut to.
  static const spotSize = 88.0;

  /// A mark that heads a screen on its own.
  static const heroSize = 120.0;

  /// The logo's frame is square but its artwork is wider than it is tall, so
  /// it is set larger than the 34pt chip it replaced to land at the same
  /// weight beside the wordmark.
  static const logoSize = 44.0;

  static const directory = 'assets/illustrations';

  /// Every mark, and the size its variants are cut to — the **largest** it
  /// is drawn anywhere. Drawn smaller it downscales, which is cheap and
  /// stays sharp; drawn larger is what goes soft. Scenario marks appear at
  /// three sizes, so they are cut at the biggest of the three.
  ///
  /// Change one of these and re-run `tool/generate_illustrations.dart`.
  static const sizes = <String, double>{
    'missed-deadlines': spotSize,
    'say-no': spotSize,
    'peer-conflict': spotSize,
    'upward-feedback': spotSize,
    'promotion-denied': spotSize,
    'high-performer': spotSize,
    'resignation': spotSize,
    'empty-progress': heroSize,
    'pro-unlock': heroSize,
    'logo': logoSize,
  };

  static Iterable<String> get names => sizes.keys;

  static String pathFor(String name) => '$directory/$name.png';

  /// Decodes every mark into the image cache.
  ///
  /// Only the screenshot harnesses need this. An asset decodes off the
  /// clock a widget test controls, so without it the marks are blank in
  /// output that is supposed to show them.
  static Future<void> precacheAll(BuildContext context) async {
    for (final name in names) {
      if (!context.mounted) return;
      await precacheImage(AssetImage(pathFor(name)), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      pathFor(name),
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
