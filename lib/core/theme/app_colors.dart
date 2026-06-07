import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const background = Color(0xFF131313);
  static const surfaceDim = Color(0xFF131313);
  static const surfaceContLowest = Color(0xFF0E0E0E);
  static const surfaceContLow = Color(0xFF1C1B1B);
  static const surfaceCont = Color(0xFF201F1F);
  static const surfaceContHigh = Color(0xFF2A2A2A);
  static const surfaceContHighest = Color(0xFF353534);
  static const surfaceBright = Color(0xFF3A3939);

  // ── Primary — Saffron Gold ─────────────────────────────────────────────────
  static const primary = Color(0xFFFFB955); // primary-fixed-dim
  static const primaryAccent = Color(0xFFF5A623); // primary-container
  static const onPrimary = Color(0xFF452B00);
  static const primaryContainer = Color(0xFFF5A623);
  static const onPrimaryContainer = Color(0xFF644000);

  // ── Secondary — Muted Teal ─────────────────────────────────────────────────
  static const secondary = Color(0xFF95D1D1);
  static const onSecondary = Color(0xFF003737);
  static const secondaryContainer = Color(0xFF0C5252);
  static const onSecondaryContainer = Color(0xFF87C3C2);

  // ── Tertiary — Dusty Rose ──────────────────────────────────────────────────
  static const tertiary = Color(0xFFF8C6C6);
  static const tertiaryContainer = Color(0xFFDBabab);
  static const onTertiaryContainer = Color(0xFF613E3E);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFD7C3AE);
  static const muted = Color(0xFF9F8E7A);
  static const mutedMore = Color(0xFF524534);

  // ── Borders ────────────────────────────────────────────────────────────────
  static const outline = Color(0xFF9F8E7A);
  static const outlineVariant = Color(0xFF524534);

  /// Hairline border: white @ 8% — for glass cards
  static const hairline = Color(0x14FFFFFF);

  /// Focus border on inputs
  static const focusBorder = primaryAccent;

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const success = Color(0xFF95D1D1); // reuse teal
  static const warning = Color(0xFFF5A623);

  // ── Chip backgrounds (low opacity) ─────────────────────────────────────────
  static const chipActiveBg = Color(0x1A95D1D1); // teal 10%
  static const chipPendingBg = Color(0x1AF8C6C6); // rose 10%
  static const chipDoneBg = Color(0x1AFFB955); // gold 10%
}
