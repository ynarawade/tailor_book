import 'package:flutter/material.dart';

class AtelierTheme {
  // Brand Colors
  static const Color brand = Color(0xFFB8926A);
  static const Color brandPrimary = Color(0xFFB8926A);
  static const Color brandSecondaryDark = Color(0xFF5E2C23);
  static const Color brandSecondaryLight = Color(0xFF8A493D);
  static const Color brandTertiaryDark = Color(0xFF3A3026);
  static const Color brandTertiaryLight = Color(0xFFEAE3DB);

  // Dark Colors
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceSecondary = Color(0xFF1C1C1E);
  static const Color darkSurfaceTertiary = Color(0xFF2C2C2E);
  static const Color darkOnSurface = Color(0xFFF4F4F4);
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkBorderStrong = Color(0xFF4A4A4C);
  static const Color darkError = Color(0xFFB85C53);
  static const Color darkMuted = Color(0xFF9A9A9A);

  // Light Colors
  static const Color lightSurface = Color(0xFFF9F8F6);
  static const Color lightSurfaceSecondary = Color(0xFFFFFFFF);
  static const Color lightSurfaceTertiary = Color(0xFFF0EFEA);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightBorder = Color(0xFFE5E3DC);
  static const Color lightBorderStrong = Color(0xFFC2BEB4);
  static const Color lightError = Color(0xFF9E473F);
  static const Color lightMuted = Color(0xFF6B6B6B);

  // ── Font Helpers ───────────────────────────────────────────────────────────
  // Display Font: Cormorant Garamond
  static TextStyle displayFont({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Cormorant Garamond',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Text / UI Font: Satoshi
  static TextStyle textFont({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Satoshi',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightSurface,
      cardColor: lightSurfaceSecondary,
      dividerColor: lightBorder,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        surfaceContainer: lightSurfaceSecondary,
        surfaceContainerHigh: lightSurfaceTertiary,
        onSurface: lightOnSurface,
        outline: lightBorder,
        outlineVariant: lightBorderStrong,
        primary: brandPrimary,
        secondary: brandSecondaryDark,
        error: lightError,
      ),
      textTheme: TextTheme(
        // Display / Titles (Cormorant Garamond)
        displayLarge: displayFont(fontSize: 32, color: lightOnSurface),
        displayMedium: displayFont(fontSize: 26, color: lightOnSurface),
        displaySmall: displayFont(fontSize: 20, color: lightOnSurface),

        // Body & UI Text (Satoshi)
        bodyLarge: textFont(fontSize: 16, color: lightOnSurface),
        bodyMedium: textFont(fontSize: 14, color: lightOnSurface),
        bodySmall: textFont(fontSize: 12, color: lightMuted),
        labelSmall: textFont(
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: lightMuted,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 0.8),
        ),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSurface,
      cardColor: darkSurfaceSecondary,
      dividerColor: darkBorder,
      colorScheme: const ColorScheme.dark(
        surface: darkSurface,
        surfaceContainer: darkSurfaceSecondary,
        surfaceContainerHigh: darkSurfaceTertiary,
        onSurface: darkOnSurface,
        outline: darkBorder,
        outlineVariant: darkBorderStrong,
        primary: brandPrimary,
        secondary: brandSecondaryLight,
        error: darkError,
      ),
      textTheme: TextTheme(
        // Display / Titles (Cormorant Garamond)
        displayLarge: displayFont(fontSize: 32, color: darkOnSurface),
        displayMedium: displayFont(fontSize: 26, color: darkOnSurface),
        displaySmall: displayFont(fontSize: 20, color: darkOnSurface),

        // Body & UI Text (Satoshi)
        bodyLarge: textFont(fontSize: 16, color: darkOnSurface),
        bodyMedium: textFont(fontSize: 14, color: darkOnSurface),
        bodySmall: textFont(fontSize: 12, color: darkMuted),
        labelSmall: textFont(
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: darkMuted,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 0.8),
        ),
      ),
    );
  }
}
