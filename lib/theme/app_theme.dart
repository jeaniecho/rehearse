import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  /// Three surfaces, and every container in the app is exactly one of them.
  ///
  /// [ground] is the page, [surface] is a sheet laid on it, [subtle] is a
  /// well cut into a sheet. Each step is a real but quiet change in
  /// luminance — sheet on ground 1.12:1, ground on well 1.13:1 — so depth is
  /// read from material rather than from a hairline doing all the work.
  ///
  /// [ground] is not a new colour. `web/manifest.json` has carried it as the
  /// browser chrome since the icons were first generated, hand-held there
  /// against a generator that keeps overwriting it, and guarded by a test.
  /// The brand had already decided; only the app had not.
  ///
  /// **This is not the cream canvas that was removed.** That one painted
  /// cards and page the same colour, which is why nothing read as laid on
  /// anything and the app read as generated. Paper needs a ground *and* a
  /// sheet; the mistake was having one surface, not a warm one. The
  /// illustrations have said so all along — `docs/ILLUSTRATIONS.md` fixes
  /// their stock at warm off-white and gives every mark "one soft contact
  /// shadow beneath", which is a shape resting on a ground exactly like
  /// this.
  static const ground = Color(0xFFF5F2EA);
  static const surface = Color(0xFFFFFFFF);

  /// A well: a track, a chip, a pill — cut into a sheet, not laid on it.
  ///
  /// Warm now, and darker than the cool grey it replaced, which no longer
  /// separated from a warm ground. The cost is that [muted] on it is 4.19:1,
  /// under the floor for body text: **a well carries [ink] or [charcoal],
  /// never [muted].**
  static const subtle = Color(0xFFEBE4D8);

  /// The cut edge of a sheet, not a Material divider. `#E4E4E7` is a cool
  /// grey, and a cool line around a warm palette is what made every surface
  /// read as a default component rather than as paper.
  static const border = Color(0xFFE8E3DB);

  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B6B72);

  /// Charcoal carries every primary action and the nav rail. [forest] is
  /// kept for progress and success only, so it still means something when it
  /// appears.
  ///
  /// There was a second green here, `#00A862`, at full saturation — the only
  /// neon value in the file. Nothing drew it: it reached `colorScheme
  /// .secondary` and stopped, one Material widget away from putting neon on
  /// a warm paper screen. [forest] holds that slot now, so the scheme and
  /// the app cannot disagree about what green is.
  static const charcoal = Color(0xFF3A342F);
  static const forest = Color(0xFF17624A);

  /// Semantic surfaces. Nothing here is decorative — a colour on screen
  /// should say what kind of thing it is.
  /// Secondary text and icons on the forest card — what [muted] is on white.
  static const onForestMuted = Color(0xFFAEC5B7);

  /// The same, on [charcoal] — the unselected label in the nav rail. Warm,
  /// because a cool grey on charcoal is the tell the whole palette avoids.
  static const onCharcoalMuted = Color(0xFFC6BEB4);

  /// Success, and the surface for whatever comes next.
  ///
  /// Rebuilt when the page went warm. It was `#E3F5EB` — hue 147, saturation
  /// 47, lightness 92.5 — which made it the one cool surface in a palette
  /// whose every other token sits at hue 37–44, and at a lightness within
  /// 1.4 of [ground] it was not a surface at all but a wash of colour on the
  /// same paper, with the hue doing all of the work and pulling the opposite
  /// way from everything around it. This is the diagnosis already written on
  /// [border] — "a cool line around a warm palette" — at sixty times the
  /// area.
  ///
  /// Now hue 132, saturation 30, lightness 89.5: less cyan, calmer, and a
  /// real step below the ground, so it reads as tinted stock rather than as
  /// a highlighter. [forest] on it is 5.93:1; [muted] is 4.31 and therefore
  /// out, the same rule as [subtle].
  static const mint = Color(0xFFDCECDF);
  static const peach = Color(0xFFFDECE0);
  static const butter = Color(0xFFFBF7A8);
  static const butterEdge = Color(0xFFE6DF6A);
  static const coral = Color(0xFFB3400F);
  static const coralBright = Color(0xFFE05B2A);

  /// The accent every illustration already carries and the UI had no answer
  /// for. `docs/ILLUSTRATIONS.md` §1 fixes the set's palette at deep green,
  /// charcoal, warm off-white, warm grey "with one small accent of muted
  /// amber #C8873A" — so amber was in every mark on every screen while the
  /// interface answered it in rust, a hotter and redder hue.
  ///
  /// Darkened from the art's #C8873A for the same reason [coral] was
  /// darkened: the original is 2.35:1 on [border], under the 3:1 floor for
  /// a graphic. This clears it at 3.28:1. It is still under the 4.5:1 floor
  /// for body text, so it draws marks and never words.
  static const amber = Color(0xFFAE6D20);

  static const sky = Color(0xFFE1ECF5);
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
      secondary: AppColors.forest,
      surface: AppColors.surface,
    );

    return ThemeData(
      // ThemeData applies this to textTheme and primaryTextTheme, and every
      // explicit TextStyle in the app inherits it through DefaultTextStyle.
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ground,
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
