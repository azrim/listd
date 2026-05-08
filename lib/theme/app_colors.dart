import 'package:flutter/material.dart';
import 'gradients.dart';

/// Design system colors for Listd.
///
/// Based on the Stitch "Midnight Studio" dark-first design language.
/// Dark theme uses indigo-tinted charcoal. Light theme uses refined corporate style.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  // BRAND COLORS
  // ─────────────────────────────────────────────────────────

  /// Primary brand color - Deep Navy (used in light theme)
  static const Color primary = Color(0xFF1A146B);

  /// Primary accent - Light indigo (used in dark theme)
  static const Color primaryLight = Color(0xFFC3C0FF);

  /// Primary container - Deep navy container
  static const Color primaryContainer = Color(0xFF312E81);

  /// On primary container
  static const Color onPrimaryContainer = Color(0xFF9C9AF4);

  /// Secondary brand color
  static const Color secondary = Color(0xFF4648D4);

  /// Secondary container
  static const Color secondaryContainer = Color(0xFF6063EE);

  /// On secondary container
  static const Color onSecondaryContainer = Color(0xFFFFFBFF);

  // ─────────────────────────────────────────────────────────
  // DARK THEME (DEFAULT)
  // ─────────────────────────────────────────────────────────

  /// Dark background - Deep charcoal with indigo undertone
  static const Color bgDeep = Color(0xFF0B1326);

  /// Dark surface - Slightly elevated from background
  static const Color bgSurface = Color(0xFF131B2E);

  /// Dark surface container - Higher elevation
  static const Color bgContainer = Color(0xFF171F33);

  /// Dark surface container high - Highest elevation
  static const Color bgContainerHigh = Color(0xFF222A3D);

  /// Dark surface container highest - Popovers/modals
  static const Color bgContainerHighest = Color(0xFF2D3449);

  // ─────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────

  /// Light background - Crisp white
  static const Color bgLight = Color(0xFFF7F9FB);

  /// Light surface
  static const Color bgLightSurface = Color(0xFFF7F9FB);

  /// Light surface container low
  static const Color bgLightContainerLow = Color(0xFFF2F4F6);

  /// Light surface container
  static const Color bgLightContainer = Color(0x0ffecef0);

  /// Light surface container high
  static const Color bgLightContainerHigh = Color(0xFFE6E8EA);

  /// Light surface container highest
  static const Color bgLightContainerHighest = Color(0xFFE0E3E5);

  // ─────────────────────────────────────────────────────────
  // GLASS EFFECT
  // ─────────────────────────────────────────────────────────

  /// Glass fill - White at 7% opacity
  static const Color glassWhite = Color(0x12FFFFFF);

  /// Glass border - White at 25% opacity
  static const Color glassBorder = Color(0x40FFFFFF);

  /// Glass border subtle - White at 10% opacity
  static const Color glassBorderSubtle = Color(0x1AFFFFFF);

  /// Glass fill - Base fill for glass card
  static const Color glassFill = Color(0x0DFFFFFF); // 5% white

  /// Glass fill light - Slightly brighter for gradient
  static const Color glassFillLight = Color(0x14FFFFFF); // 8% white

  // ─────────────────────────────────────────────────────────
  // TEXT COLORS
  // ─────────────────────────────────────────────────────────

  /// Dark text primary - White-smoke for max contrast
  static const Color textPrimary = Color(0xFFDAE2FD);

  /// Dark text secondary - Muted gray
  static const Color textSecondary = Color(0xFFC8C5D3);

  /// Dark text hint - Lowest contrast
  static const Color textHint = Color(0xFF918F9C);

  /// Light text primary - Near black
  static const Color textPrimaryLight = Color(0xFF191C1E);

  /// Light text secondary - Muted gray
  static const Color textSecondaryLight = Color(0xFF474651);

  /// Light text hint - Lowest contrast
  static const Color textHintLight = Color(0xFF777682);

  // ─────────────────────────────────────────────────────────
  // STATUS COLORS
  // ─────────────────────────────────────────────────────────

  /// Error color (light)
  static const Color error = Color(0xFFBA1A1A);

  /// Error color (dark) - Softened for dark mode
  static const Color errorDark = Color(0xFFFFB4AB);

  /// Error container
  static const Color errorContainer = Color(0xFF93000A);

  /// Success - Desaturated to match indigo palette
  static const Color success = Color(0xFF4CAF50);

  /// Success dark mode
  static const Color successDark = Color(0xFF81C784);

  /// Warning
  static const Color warning = Color(0xFFFFCA28);

  /// Warning dark mode
  static const Color warningDark = Color(0xFFFFB688);

  // ─────────────────────────────────────────────────────────
  // OUTLINE COLORS
  // ─────────────────────────────────────────────────────────

  /// Outline (light theme)
  static const Color outline = Color(0xFF777682);

  /// Outline variant (light theme)
  static const Color outlineVariant = Color(0xFFC8C5D3);

  /// Outline (dark theme)
  static const Color outlineDark = Color(0xFF918F9C);

  /// Outline variant (dark theme)
  static const Color outlineVariantDark = Color(0xFF474651);

  // ─────────────────────────────────────────────────────────
  // GRADIENTS (defined in AppGradients)
  // ─────────────────────────────────────────────────────────

  // Backward compatibility aliases
  static const Color danger = error;

  /// Glassmorphism primary - for active nav, checkbox glow
  static const Color glassPrimary = Color(0xFF5C6BC0);

  /// Glassmorphism primary light - for gradient
  static const Color glassPrimaryLight = Color(0xFF7986CB);

  /// Glass dark mid - for gradient layer 2
  static const Color bgMid = Color(0xFF0E1030);

  /// Glass dark surface - for gradient layer 3
  static const Color bgSurfaceDark = Color(0xFF131440);

  /// Background gradient (dark) - for backward compatibility
  static const backgroundGradient = AppGradients.backgroundDark;
}
