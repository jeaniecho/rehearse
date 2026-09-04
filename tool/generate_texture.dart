// Writes the tileable paper stock grain.
//
//   flutter test tool/generate_texture.dart
//
// Run as a test for the same reason as the other generators: it is the
// supported way to get the engine's PNG encoder outside a running app.
//
// Per-pixel noise on purpose. Anything with spatial structure — fibres,
// blotches, a gradient — has to be made to wrap or it shows a seam every
// tile. White noise has no structure to break, so it tiles by construction.
//
// Light and dark specks in the same pass, because a single-polarity grain
// only darkens: over a colour it reads as dirt, where paper reads as fibre
// catching and losing the light.
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _size = 128;

/// How opaque the strongest speck is, out of 255. Deliberately tiny — this
/// is multiplied down again by `Paper.grain`'s own opacity at use.
const _peak = 26;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('derive the paper grain', () async {
    // Seeded, so regenerating does not produce a diff for no reason.
    final random = Random(7);
    final pixels = Uint8List(_size * _size * 4);

    for (var i = 0; i < _size * _size; i++) {
      final light = random.nextBool();
      final value = light ? 255 : 0;
      // Squared, so most pixels are nearly clear and a few carry the grain.
      final t = random.nextDouble();
      final alpha = (_peak * t * t).round();

      pixels[i * 4] = value;
      pixels[i * 4 + 1] = value;
      pixels[i * 4 + 2] = value;
      pixels[i * 4 + 3] = alpha;
    }

    final image = await _decode(pixels);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final file = File('assets/texture/stock.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    stdout.writeln('wrote ${file.path}  ${_size}x$_size');
  });
}

Future<ui.Image> _decode(Uint8List pixels) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    _size,
    _size,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}
