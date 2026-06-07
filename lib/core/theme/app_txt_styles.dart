import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Inter ──────────────────────────────────────────────────────────────────

  /// 32 / 700 — screen titles
  static TextStyle displayLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
        color: color,
      );

  /// 24 / 600 — section headings
  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
        color: color,
      );

  /// 20 / 600 — card titles, customer name
  static TextStyle headlineSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: color,
      );

  /// 16 / 400 — body text
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  /// 14 / 400 — secondary body
  static TextStyle bodyMd({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  /// 12 / 400 — timestamps, helper text
  static TextStyle metadataSm({Color color = AppColors.muted}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: color,
      );

  // ── JetBrains Mono — labels, IDs, numeric values ──────────────────────────

  /// 12 / 500 — field labels, badges
  static TextStyle labelMd({Color color = AppColors.muted}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        color: color,
      );

  /// 11 / 500 — bottom nav labels
  static TextStyle navLabel({Color color = AppColors.muted}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
