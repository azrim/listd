import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application text styles based on Manrope typography.
class AppTextStyles {
  AppTextStyles._();

  // ─────────────────────────────────────────────────────────
  // DISPLAY STYLES
  // ─────────────────────────────────────────────────────────

  /// Display - 48px, weight 800
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.02,
  );

  // ─────────────────────────────────────────────────────────
  // HEADING STYLES
  // ─────────────────────────────────────────────────────────

  /// H1 - 32px, weight 700
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.01,
  );

  /// H2 - 24px, weight 600
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.01,
  );

  /// H3 - 20px, weight 600
  static TextStyle get h3 =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);

  // ─────────────────────────────────────────────────────────
  // BODY STYLES
  // ─────────────────────────────────────────────────────────

  /// Body Large - 18px, weight 400
  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w400, height: 1.6);

  /// Body Medium - 16px, weight 400
  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);

  /// Body Small - 14px, weight 400
  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  // ─────────────────────────────────────────────────────────
  // LABEL STYLES
  // ─────────────────────────────────────────────────────────

  /// Label Medium - 12px, weight 600, uppercase
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.05,
  );

  /// Label Small - 12px, weight 500
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.02,
  );

  // ─────────────────────────────────────────────────────────
  // BUTTON STYLES
  // ─────────────────────────────��───────────────────────────

  /// Button - 14px, weight 600
  static TextStyle get button =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  // ─────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
