import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF4F0E7);
  static const surface = Color(0xFFFFFDF8);
  static const ink = Color(0xFF18211D);
  static const muted = Color(0xFF59645E);
  static const forest = Color(0xFF214E3B);
  static const mint = Color(0xFFDDEADF);
  static const coral = Color(0xFFB94A2F);
  static const coralBright = Color(0xFFE86D4A);
  static const peach = Color(0xFFF8D9C8);
  static const lavender = Color(0xFFE7E0F2);
  static const sky = Color(0xFFD7E5EF);
  static const butter = Color(0xFFF4E5BE);
  static const rose = Color(0xFFF2DBE1);
  static const border = Color(0xFFE4DFD3);
}

abstract final class AppTheme {
  static ThemeData get light => withFont(null);

  /// The theme names no font, so the app uses each platform's own.
  ///
  /// [fontFamily] exists for `tool/generate_screenshots.dart`: the test
  /// environment ships no fonts at all, so the generator loads one and has
  /// to be able to tell the theme about it. It threads through here rather
  /// than being applied to the theme afterwards because `ButtonStyle`'s
  /// `textStyle` replaces rather than merges, so a family applied to the
  /// text theme alone never reaches a button label.
  static ThemeData withFont(String? fontFamily) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
      primary: AppColors.forest,
      secondary: AppColors.coral,
      surface: AppColors.surface,
    );

    return ThemeData(
      // ThemeData applies this to textTheme and primaryTextTheme, and every
      // explicit TextStyle in the app inherits it through DefaultTextStyle.
      fontFamily: fontFamily,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 44,
          height: 1.02,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.8,
        ),
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 32,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
