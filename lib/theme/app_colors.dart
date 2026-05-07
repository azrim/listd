import 'package:flutter/material.dart';

/// Design system colors for Listd glassmorphism UI
class AppColors {
  AppColors._();

  // ── Signature brand color ──
  static const Color primary = Color(0xFF5C6BC0);
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color primaryDark = Color(0xFF3949AB);
  static const Color primaryGlow = Color(0xFF5C6BC0);

  // ── Backgrounds ──
  static const Color bgDeep = Color(0xFF07081A);
  static const Color bgMid = Color(0xFF0E1030);
  static const Color bgSurface = Color(0xFF131440);

  // ── Glass effect ──
  static const Color glassWhite = Color(0x12FFFFFF); // 7% white
  static const Color glassBorder = Color(0x40FFFFFF); // 25% white

  // ── Status ──
  static const Color danger = Color(0xFFEF5350);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFCA28);

  // ── Text ──
  static const Color textPrimary = Color(0xF2FFFFFF); // 95%
  static const Color textSecondary = Color(0x8CFFFFFF); // 55%
  static const Color textHint = Color(0x59FFFFFF); // 35%

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgMid, bgSurface],
    stops: [0.0, 0.5, 1.0],
  );
}