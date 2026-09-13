// Shared plumbing for the two tools that render the real app to PNG:
// `generate_screenshots.dart`, which produces the store assets, and
// `ui_review.dart`, which produces images to look at.
//
// Both run as tests, because that is the supported way to get a Flutter
// canvas outside a running app — and a test environment loads no fonts of
// its own, so without [loadHarnessFonts] every glyph in either tool's output
// is a box. That is the whole reason this file exists: two copies of it
// would drift, and the failure is silent in one of them and shipped to the
// App Store in the other.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/theme/app_theme.dart';

/// The one family the app does not bundle: the streak badge leads with an
/// emoji, and no font in a test environment can draw one.
const emojiFamily = 'Apple Color Emoji';

/// What loaded, and the theme to render with.
class HarnessFonts {
  const HarnessFonts({required this.brandLoaded, required this.emojiLoaded});

  /// False means every glyph will be a box. `generate_screenshots.dart`
  /// turns this into a warning, because the images are unusable.
  final bool brandLoaded;
  final bool emojiLoaded;

  /// The app's own theme, plus the emoji family this harness had to supply.
  ThemeData get theme =>
      AppTheme.withFallback(emojiLoaded ? const [emojiFamily] : null);
}

/// Loads the typefaces the app bundles, the Material icon font, and the
/// system emoji font.
///
/// The bundled families are what make the output match the real app on any
/// machine rather than only on the one that authored it.
Future<HarnessFonts> loadHarnessFonts() async {
  var brand = true;
  try {
    final sans = FontLoader(AppTheme.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans[wght].ttf'))
      ..addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-Italic[wght].ttf'),
      );
    await sans.load();

    // The serif too, or the coaching report — the one screen that carries a
    // quote — comes out with the quote and the rewrite set in boxes.
    final serif = FontLoader(AppTheme.serifFontFamily)
      ..addFont(rootBundle.load('assets/fonts/Literata[opsz,wght].ttf'));
    await serif.load();
  } on Object {
    brand = false;
  }

  final emoji = await _register(emojiFamily, const [
    '/System/Library/Fonts/Apple Color Emoji.ttc',
  ]);

  // Icons live in a separate family the test environment does not load
  // either, so without this every icon renders as a box too.
  final root = Platform.environment['FLUTTER_ROOT'];
  final home = Platform.environment['HOME'];
  const suffix = 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  await _register('MaterialIcons', [
    if (root != null && root.isNotEmpty) '$root/$suffix',
    if (home != null) '$home/Dev/flutter/$suffix',
    if (home != null) '$home/flutter/$suffix',
  ]);

  return HarnessFonts(brandLoaded: brand, emojiLoaded: emoji);
}

Future<bool> _register(String family, List<String> candidates) async {
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    try {
      final bytes = await file.readAsBytes();
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return true;
    } on Object {
      continue;
    }
  }
  return false;
}

/// Lays the view out as a real device: [size] physical pixels across at
/// [ratio], with a notch and a home indicator so the output can show a
/// safe-area mistake rather than hiding it.
void sizeAsDevice(WidgetTester tester, Size size, double ratio) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = ratio;
  final insets = FakeViewPadding(top: 59 * ratio, bottom: 34 * ratio);
  tester.view.viewPadding = insets;
  tester.view.padding = insets;
}

/// Paints whatever [boundary] wraps into a PNG at [path].
Future<void> writePng(
  WidgetTester tester,
  GlobalKey boundary,
  String path, {
  required double pixelRatio,
}) async {
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    stdout.writeln('wrote ${file.path}  ${image.width}x${image.height}');
    image.dispose();
  });
}

/// The iOS status bar, drawn. Both store tools frame the app inside a phone,
/// and a phone with no status bar reads as a mockup of one — but a widget
/// test has no system chrome to capture, so it is drawn here.
///
/// 9:41 is Apple's own convention in marketing images. The height matches the
/// top padding `sizeAsDevice` reserves, so this sits in space the screens
/// already leave rather than over their content.
class StoreStatusBar extends StatelessWidget {
  const StoreStatusBar({this.height = 59, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.ink;
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Container(
                width: 124,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 14, 26, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '9:41',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.signal_cellular_alt, size: 16, color: ink),
                    const SizedBox(width: 5),
                    const Icon(Icons.wifi, size: 16, color: ink),
                    const SizedBox(width: 5),
                    Transform.rotate(
                      angle: 1.5708,
                      child: const Icon(
                        Icons.battery_full,
                        size: 18,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
