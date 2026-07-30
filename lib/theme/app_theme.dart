import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central palette + typography for Reel Roulette.
///
/// A dark "cinema" backdrop with a neon amber/magenta accent, display type set
/// in Bebas Neue and body text in Inter (both fetched at runtime by
/// `google_fonts`; bundle them as assets for fully offline builds).
class AppTheme {
  AppTheme._();

  // Palette ------------------------------------------------------------------
  static const Color background = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF15151F);
  static const Color surfaceHigh = Color(0xFF1E1E2C);
  static const Color outline = Color(0xFF2C2C3D);

  static const Color accent = Color(0xFFFFB300); // marquee amber
  static const Color accentAlt = Color(0xFFFF3D71); // magenta pop
  static const Color imdbYellow = Color(0xFFF5C518);

  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textMuted = Color(0xFF9A9AB0);

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [accent, accentAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backdropGradient = LinearGradient(
    colors: [Color(0xFF12121C), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Typography ---------------------------------------------------------------

  /// Big condensed marquee type (Bebas Neue).
  static TextStyle display(double size, {Color? color, double? letterSpacing}) {
    return GoogleFonts.bebasNeue(
      fontSize: size,
      color: color ?? textPrimary,
      letterSpacing: letterSpacing ?? 1.5,
      height: 1.0,
    );
  }

  static TextStyle body(double size,
      {Color? color, FontWeight weight = FontWeight.w400, double height = 1.4}) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color ?? textPrimary,
      fontWeight: weight,
      height: height,
    );
  }

  // ThemeData ----------------------------------------------------------------
  static ThemeData get themeData {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accentAlt,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      splashColor: accent.withOpacity(0.12),
      highlightColor: Colors.transparent,
    );
  }
}
