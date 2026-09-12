// Renders the brand mark to the master PNGs that flutter_launcher_icons
// fans out into every platform icon set.
//
//   flutter test tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// Run as a test because that is the supported way to get a real Flutter
// canvas and a PNG encoder outside a running app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/theme/app_theme.dart';
import 'package:rehearse/theme/brand_mark_painter.dart';

const _size = 1024.0;

void main() {
  Future<void> render(
    WidgetTester tester,
    String name,
    BrandMarkPainter painter,
  ) async {
    tester.view.physicalSize = const Size(_size, _size);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          child: CustomPaint(size: const Size.square(_size), painter: painter),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final image = await captureImage(
        tester.element(find.byType(CustomPaint).first),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('assets/icon/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
      stdout.writeln('wrote ${file.path}');
    });
  }

  testWidgets('generate app icons', (tester) async {
    // assets/icon/app_icon.png is not drawn here. The store master is a
    // paper cut-out illustration of the same two bubbles, and it is the one
    // surface where the texture is worth the file size. The layers below
    // stay drawn, because Android's adaptive and themed icons are flat by
    // definition and a rendered texture would only muddy them.

    // Android adaptive foreground: transparent, and sized so the mark fills
    // about two thirds of the circle the launcher masks it to. Note that
    // flutter_launcher_icons insets this layer by a further 16%, which is
    // already accounted for here — check the composite, not this number.
    await render(
      tester,
      'app_icon_foreground',
      const BrandMarkPainter(scale: 0.95),
    );

    // Android 13 themed icons: one silhouette, the gap cut out rather than
    // painted, so the system can tint the whole thing.
    await render(
      tester,
      'app_icon_monochrome',
      const BrandMarkPainter(
        frontBubble: Color(0xFFFFFFFF),
        backBubble: Color(0xFFFFFFFF),
        separator: null,
        scale: 0.95,
      ),
    );

    // Launch screen: transparent, and in the icon's own pairing — forest
    // behind, white in front — rather than the inked single colour it used
    // to be. White on `ground` is all but invisible, so the separator does
    // the work: forest, which outlines the front bubble against the splash
    // and disappears into the back one where they overlap, exactly as the
    // icon's paper cut-out reads.
    await render(
      tester,
      'launch_mark',
      const BrandMarkPainter(
        frontBubble: AppColors.surface,
        backBubble: AppColors.forest,
        separator: AppColors.forest,
        scale: 0.9,
      ),
    );
  });
}
