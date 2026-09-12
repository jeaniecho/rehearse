import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearse/theme/app_theme.dart';

/// Guards the generated launcher icons.
///
/// These are build outputs committed to the repo, so nothing else would
/// notice if a regeneration produced the wrong shape — or if someone
/// reintroduced the stock Flutter logo.
void main() {
  group('master art', () {
    for (final name in [
      'app_icon',
      'app_icon_foreground',
      'app_icon_monochrome',
      'launch_mark',
    ]) {
      test('$name is a 1024 square', () {
        final png = _png('assets/icon/$name.png');
        expect(png.width, 1024);
        expect(png.height, 1024);
      });
    }

    test('the layers that sit on something else carry transparency', () {
      // A Flutter canvas always writes RGBA, so the master store icon has an
      // alpha channel even though every pixel is opaque; the iOS test below
      // is what guards the channel actually shipped to the store. These
      // three are transparent by design and would be wrong otherwise.
      expect(_png('assets/icon/app_icon_foreground.png').hasAlpha, isTrue);
      expect(_png('assets/icon/app_icon_monochrome.png').hasAlpha, isTrue);
      expect(_png('assets/icon/launch_mark.png').hasAlpha, isTrue);
    });
  });

  group('iOS', () {
    test('the store icon is 1024 square with no alpha channel', () {
      // App Store Connect rejects an icon with transparency, and it is the
      // last step of submission, which is the worst time to find out.
      final png = _png(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
      );

      expect(png.width, 1024);
      expect(png.height, 1024);
      expect(png.hasAlpha, isFalse);
    });

    test('every size in the app icon set is present and square', () {
      final directory = Directory(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      );
      final icons = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .toList();

      expect(icons.length, greaterThanOrEqualTo(15));
      for (final icon in icons) {
        final png = _png(icon.path);
        expect(png.width, png.height, reason: icon.path);
      }
    });

    test('the launch image is the brand mark, not the Flutter logo', () {
      for (final (name, size) in [
        ('LaunchImage.png', 120),
        ('LaunchImage@2x.png', 240),
        ('LaunchImage@3x.png', 360),
      ]) {
        final png = _png(
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/$name',
        );
        expect(png.width, size, reason: name);
        expect(png.hasAlpha, isTrue, reason: '$name sits on the splash colour');
      }
    });
  });

  group('Android', () {
    test('an adaptive icon is declared with all three layers', () {
      final xml = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();

      expect(xml, contains('<background'));
      expect(xml, contains('<foreground'));
      expect(xml, contains('<monochrome'));
    });

    test('the icon and splash colours are the brand ones', () {
      final colors = File(
        'android/app/src/main/res/values/colors.xml',
      ).readAsStringSync();

      expect(colors, contains(_hex(AppColors.forest)));
      expect(colors, contains(_hex(AppColors.ground)));
    });

    test('both light and dark splashes draw the mark', () {
      for (final directory in ['drawable', 'drawable-v21']) {
        final xml = File(
          'android/app/src/main/res/$directory/launch_background.xml',
        ).readAsStringSync();

        expect(xml, contains('@color/launch_background'), reason: directory);
        expect(xml, contains('@drawable/launch_mark'), reason: directory);
        expect(
          xml,
          isNot(contains('@android:color/white')),
          reason: '$directory still has the default white splash',
        );
      }
    });

    test('the launcher icon exists at every density', () {
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        final root = 'android/app/src/main/res';
        expect(
          File('$root/mipmap-$density/ic_launcher.png').existsSync(),
          isTrue,
          reason: density,
        );
        expect(
          File('$root/drawable-$density/launch_mark.png').existsSync(),
          isTrue,
          reason: density,
        );
      }
    });

    // 120dp at every density, which is the size iOS uses and the size
    // `_Launch` paints. They were 96dp until 2026-09-13, so the mark grew a
    // quarter at the handoff on Android alone — the one platform where the
    // seam was visible.
    test('the launch mark is 120dp at every density', () {
      for (final (density, size) in [
        ('mdpi', 120),
        ('hdpi', 180),
        ('xhdpi', 240),
        ('xxhdpi', 360),
        ('xxxhdpi', 480),
      ]) {
        final png = _png(
          'android/app/src/main/res/drawable-$density/launch_mark.png',
        );
        expect(png.width, size, reason: density);
        expect(png.height, size, reason: density);
      }
    });
  });

  group('web', () {
    test('the favicon and PWA icons are generated', () {
      for (final (path, size) in [
        ('web/icons/Icon-192.png', 192),
        ('web/icons/Icon-512.png', 512),
        ('web/icons/Icon-maskable-192.png', 192),
        ('web/icons/Icon-maskable-512.png', 512),
      ]) {
        final png = _png(path);
        expect(png.width, size, reason: path);
      }
      expect(File('web/favicon.png').existsSync(), isTrue);
    });

    test('the manifest uses the brand canvas', () {
      final manifest = File('web/manifest.json').readAsStringSync();
      expect(manifest, contains(_hex(AppColors.ground)));
    });
  });
}

/// Just enough PNG to read the header: signature, then an IHDR giving the
/// dimensions and a colour type whose bit 2 means an alpha channel.
({int width, int height, bool hasAlpha}) _png(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing $path');

  final bytes = file.readAsBytesSync();
  expect(bytes.sublist(0, 8), [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
  ], reason: '$path is not a PNG');

  final header = ByteData.sublistView(bytes, 16, 26);
  final colorType = header.getUint8(9);

  return (
    width: header.getUint32(0),
    height: header.getUint32(4),
    // 4 = grey + alpha, 6 = RGBA.
    hasAlpha: colorType == 4 || colorType == 6,
  );
}

/// The palette in the form the Android resource files write it, so these
/// assertions follow AppColors instead of being retyped when it changes.
String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';
