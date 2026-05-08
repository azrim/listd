import 'package:flutter/material.dart';

/// Application gradients based on the Midnight Studio design language.
class AppGradients {
  AppGradients._();

  /// Primary brand gradient - Violet to blue
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF312E81), // Deep navy
      Color(0xFF6366F1), // Vibrant indigo
    ],
  );

  /// Primary gradient dark mode
  static const LinearGradient primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF312E81),
      Color(0xFF7C3AED), // Violet accent
    ],
  );

  /// Background gradient for auth screen
  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1326), Color(0xFF131B2E), Color(0xFF171F33)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Screen gradient - deep to mid to surface for each screen
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF07081A), Color(0xFF0E1030), Color(0xFF131440)],
  );

  /// Sidebar active gradient - used for active nav item
  static const LinearGradient navActiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
  );

  /// Background gradient light
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F9FB), Color(0xFFF2F4F6)],
  );

  /// Surface subtle gradient
  static const LinearGradient surfaceGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
  );

  /// Card subtle gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF171F33)],
  );

  /// Success gradient
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  /// Error gradient
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  /// Overlay gradient for modals
  static const LinearGradient overlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x80000000)],
  );
}
