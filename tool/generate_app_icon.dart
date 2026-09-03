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
    // Store and web: opaque, mark sized for a square that gets corner-masked.
    await render(
      tester,
      'app_icon',
      const BrandMarkPainter(background: AppColors.forest, scale: 0.96),
    );

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

    // Launch screen: transparent, and inked so it reads on the canvas the
    // splash paints behind it. The cream front bubble of the app icon would
    // be invisible there.
    await render(
      tester,
      'launch_mark',
      const BrandMarkPainter(
        frontBubble: AppColors.forest,
        separator: AppColors.canvas,
        scale: 0.9,
      ),
    );
  });
}
