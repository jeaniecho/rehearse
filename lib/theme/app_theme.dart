import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  /// Cards are white on white; the border is what separates them. The old
  /// cream canvas was most of what made the app read as generated.
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const subtle = Color(0xFFF3F3F5);

  /// The cut edge of a sheet, not a Material divider. `#E4E4E7` is a cool
  /// grey, and a cool line around a warm palette is what made every surface
  /// read as a default component rather than as paper.
  static const border = Color(0xFFE8E3DB);

  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B6B72);

  /// Charcoal carries every primary action. Green is kept for progress and
  /// success only, so it still means something when it appears.
  static const charcoal = Color(0xFF3A342F);
  static const green = Color(0xFF00A862);
  static const forest = Color(0xFF17624A);

  /// Semantic surfaces. Nothing here is decorative — a colour on screen
  /// should say what kind of thing it is.
  /// Secondary text and icons on the forest card — what [muted] is on white.
  static const onForestMuted = Color(0xFFAEC5B7);

  static const mint = Color(0xFFE3F5EB);
  static const peach = Color(0xFFFDECE0);
  static const butter = Color(0xFFFBF7A8);
  static const butterEdge = Color(0xFFE6DF6A);
  static const coral = Color(0xFFB3400F);
  static const coralBright = Color(0xFFE05B2A);
  static const lavender = Color(0xFFECE8F7);
  static const sky = Color(0xFFE1ECF5);
  static const rose = Color(0xFFF7E5EA);
}

abstract final class AppTheme {
  /// Bundled, so Android and the web no longer fall back to something else
  /// and the app stops looking unlike its own screenshots.
  static const fontFamily = 'Plus Jakarta Sans';

  /// The second voice: what a person said, rather than what the app says
  /// about it.
  ///
  /// It reaches exactly two styles, both on the results screen — the quote
  /// and the rewrite offered back — because a note card has to hold your
  /// line, our read of it, and a better line in one column, and one family
  /// can only tell those apart by convention. Everything else in the app
  /// stays [fontFamily]: headings, labels, scores, buttons, the wordmark,
  /// and the practice transcript, which is scanned turn by turn rather
  /// than read.
  ///
  /// Not applied through `ThemeData`, which takes a single family. Widen
  /// this and the distinction stops meaning anything.
  static const serifFontFamily = 'Literata';

  /// The sans catches anything the serif cannot draw, rather than a row of
  /// notdef boxes. Both serif strings can come from the model, and the
  /// bundled Literata is subset to latin — so this is the same bet as
  /// every other fallback in the app: degrade, never break.
  static const serifFallback = [fontFamily];

  /// Dark status bar content, on every screen.
  ///
  /// Not the default it looks like: an `AppBar` picks its overlay style by
  /// estimating the brightness of its own background, and this app bar is
  /// transparent — which estimates as dark and asks the system for white
  /// icons, on a white bar. Set here so the app bars and the two screens
  /// that have none all say the same thing.
  ///
  /// The two brightnesses are opposites on purpose: Android names the
  /// icons, iOS names the background behind them.
  static const overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static ThemeData get light => withFallback(null);

  /// [fontFamilyFallback] exists for `tool/generate_screenshots.dart`: the
  /// test environment can draw no emoji, so the harness supplies one. It
  /// threads through here rather than being applied to the theme afterwards
  /// because `ButtonStyle`'s `textStyle` replaces rather than merges, so a
  /// family applied to the text theme alone never reaches a button label.
  static ThemeData withFallback(List<String>? fontFamilyFallback) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
      primary: AppColors.charcoal,
      secondary: AppColors.green,
      surface: AppColors.surface,
    );

    return ThemeData(
      // ThemeData applies this to textTheme and primaryTextTheme, and every
      // explicit TextStyle in the app inherits it through DefaultTextStyle.
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 40,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
        ),
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 30,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 23,
          height: 1.18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        // Material's own shadow rather than Paper.lift, because Card takes
        // an elevation and not a shadow list. Tuned to sit at the same
        // weight; if one moves, move the other.
        elevation: 1,
        shadowColor: const Color(0x26332E29),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
