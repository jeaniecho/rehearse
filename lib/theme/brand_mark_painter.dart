import 'package:flutter/rendering.dart';

import 'app_theme.dart';

/// The Rehearse mark: two speech bubbles, one interrupting the other.
///
/// Drawn rather than shipped as art so it is built from the same
/// [AppColors] the rest of the app uses and cannot drift from the brand.
/// `tool/generate_app_icon.dart` renders it to the platform icon sets.
///
/// Everything is laid out on a 1024 grid and scaled, so the same painter
/// serves a 20px favicon and a 1024px store icon.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    this.background,
    this.frontBubble = AppColors.surface,
    this.backBubble = AppColors.coral,
    this.separator = AppColors.forest,
    this.scale = 1,
  });

  /// Null leaves the mark transparent, which is what an Android adaptive
  /// foreground and a launch image both need.
  final Color? background;
  final Color frontBubble;
  final Color backBubble;

  /// Drawn as a gap between the two bubbles so the front one reads as being
  /// in front even where they overlap. Null erases instead of painting,
  /// which is what a single-colour Android monochrome layer needs.
  final Color? separator;

  /// Shrinks the mark about the centre. Android adaptive icons crop to the
  /// middle ~66%, so the foreground layer needs room to survive a circle
  /// mask.
  final double scale;

  static const _grid = 1024.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (background case final color?) {
      canvas.drawRect(Offset.zero & size, Paint()..color = color);
    }

    canvas.save();
    canvas.scale(size.width / _grid, size.height / _grid);
    if (scale != 1) {
      canvas
        ..translate(_grid / 2, _grid / 2)
        ..scale(scale)
        ..translate(-_grid / 2, -_grid / 2);
    }

    // The composition is centred on the grid: x 166..858, y 190..834.
    final back = RRect.fromLTRBR(430, 190, 858, 498, const Radius.circular(86));
    final front = _frontBubble();
    // Punching the front bubble's silhouette out of the back one is what
    // keeps the two from merging into a single blob at small sizes.
    final gap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 54
      ..strokeJoin = StrokeJoin.round;

    if (separator case final color?) {
      gap.color = color;
    } else {
      // No colour to paint the gap in, so cut it out of the layer instead.
      gap.blendMode = BlendMode.clear;
      canvas.saveLayer(const Rect.fromLTWH(0, 0, _grid, _grid), Paint());
    }

    canvas
      ..drawRRect(back, Paint()..color = backBubble)
      ..drawPath(front, gap)
      ..drawPath(front, Paint()..color = frontBubble);

    if (separator == null) canvas.restore();
    canvas.restore();
  }

  /// A rounded speech bubble whose tail grows out of the bottom-left corner.
  static Path _frontBubble() {
    final body = Path()
      ..addRRect(
        RRect.fromLTRBR(166, 356, 662, 706, const Radius.circular(96)),
      );
    // A wedge growing out of the bottom-left corner, blunted at the tip so
    // it survives being scaled down to a favicon.
    final tail = Path()
      ..moveTo(258, 600)
      ..lineTo(470, 600)
      ..lineTo(330, 812)
      ..quadraticBezierTo(300, 834, 286, 806)
      ..lineTo(258, 700)
      ..close();

    return Path.combine(PathOperation.union, body, tail);
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) =>
      background != oldDelegate.background ||
      frontBubble != oldDelegate.frontBubble ||
      backBubble != oldDelegate.backBubble ||
      separator != oldDelegate.separator ||
      scale != oldDelegate.scale;
}
