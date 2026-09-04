// Cuts the bundled illustration variants from the masters in `art/`.
//
//   flutter test tool/generate_illustrations.dart
//
// Run as a test because that is the supported way to get the engine's image
// codec outside a running app — the same reason as generate_app_icon.dart.
//
// The masters are 1254px and about 11 MB together, which is more than the
// whole rest of the app. Nothing is shown above 120pt, so what ships is cut
// to the size it is actually drawn at, at each of the three pixel ratios
// Flutter resolves.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/widgets/illustration.dart';

const _masters = 'art/illustrations';

/// The pixel ratios worth shipping. 1.0 is the file itself; Flutter finds
/// the rest in the `N.Nx` subdirectories beside it.
const _ratios = [1.0, 2.0, 3.0];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('derive the bundled illustrations', () async {
    var wrote = 0;

    for (final MapEntry(key: name, value: logical)
        in Illustration.sizes.entries) {
      final master = File('$_masters/$name.png');
      expect(
        master.existsSync(),
        isTrue,
        reason: 'no master for $name — see docs/ILLUSTRATIONS.md',
      );

      final bytes = await master.readAsBytes();
      for (final ratio in _ratios) {
        final pixels = (logical * ratio).round();

        // Resizing in the codec rather than on a canvas: this path mipmaps,
        // and a 1254 -> 40 downscale done in one bilinear step turns paper
        // texture into noise.
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: pixels,
          targetHeight: pixels,
        );
        final frame = await codec.getNextFrame();
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        frame.image.dispose();
        codec.dispose();

        final variant = ratio == 1.0 ? '' : '/${ratio}x';
        final file = File('${Illustration.directory}$variant/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        wrote++;
      }
    }

    stdout.writeln('wrote $wrote files to ${Illustration.directory}');
  });
}
