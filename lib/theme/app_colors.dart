import 'package:flutter/material.dart';

/// Listd 2026 design tokens.
///
/// One typeface, one accent, two surfaces. The whole product is built on
/// the table below — there are no other hex literals anywhere in
/// `lib/theme/`. Old aliases (`AppColors.primary`, `AppColors.bgSurface`,
/// `AppColors.glassWhite`, …) are kept as backward-compat surfaces and
/// just resolve back to the same tokens, so existing widgets pick up the
/// new look automatically.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  //  ACCENT — the *only* hue that appears outside state pills.
  // ─────────────────────────────────────────────────────────

  /// Light-mode accent (selection, focus ring, primary button).
  static const Color accent = Color(0xFF4F46E5);

  /// Dark-mode accent — adjusted for contrast on near-black surfaces.
  static const Color accentDark = Color(0xFF7C7BFF);

  /// Tinted fill behind a selected row in light mode.
  static const Color accentSoft = Color(0xFFEEF0FF);

  /// Tinted fill behind a selected row in dark mode.
  static const Color accentSoftDark = Color(0xFF1B1D3A);

  // ─────────────────────────────────────────────────────────
  //  LIGHT NEUTRALS
  // ─────────────────────────────────────────────────────────

  static const Color _lSurface = Color(0xFFFFFFFF); // app background
  static const Color _lSurfaceElevated = Color(0xFFFAFAFA); // rail/inspector
  static const Color _lSurfaceSunken = Color(0xFFF4F4F5); // hover/capture
  static const Color _lSurfaceDeeper = Color(0xFFEEEEF0); // press/header
  static const Color _lBorder = Color(0xFFE5E5E7);
  static const Color _lBorderStrong = Color(0xFFCFCFD3);
  static const Color _lTextPrimary = Color(0xFF0A0A0B);
  static const Color _lTextSecondary = Color(0xFF5C5C66);
  static const Color _lTextTertiary = Color(0xFF9A9AA3);

  // ─────────────────────────────────────────────────────────
  //  DARK NEUTRALS
  // ─────────────────────────────────────────────────────────

  static const Color _dSurface = Color(0xFF0B0B0E);
  static const Color _dSurfaceElevated = Color(0xFF121217);
  static const Color _dSurfaceSunken = Color(0xFF191920);
  static const Color _dSurfaceDeeper = Color(0xFF1F1F27);
  static const Color _dBorder = Color(0xFF26262C);
  static const Color _dBorderStrong = Color(0xFF3A3A42);
  static const Color _dTextPrimary = Color(0xFFF2F2F4);
  static const Color _dTextSecondary = Color(0xFF9C9CA6);
  static const Color _dTextTertiary = Color(0xFF5F5F6B);

  // ─────────────────────────────────────────────────────────
  //  FUNCTIONAL — used only for state pills, never for emphasis.
  // ─────────────────────────────────────────────────────────

  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF22C55E);
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFEF4444);

  // ─────────────────────────────────────────────────────────
  //  COLOR SCHEMES — explicit, no fromSeed.
  // ─────────────────────────────────────────────────────────

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: accent,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: accentSoft,
    onPrimaryContainer: accent,
    inversePrimary: accentDark,
    secondary: _lTextSecondary,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: _lSurfaceSunken,
    onSecondaryContainer: _lTextPrimary,
    tertiary: accent,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: accentSoft,
    onTertiaryContainer: accent,
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: error,
    surface: _lSurface,
    onSurface: _lTextPrimary,
    surfaceContainerLowest: _lSurface,
    surfaceContainerLow: _lSurfaceElevated,
    surfaceContainer: _lSurfaceSunken,
    surfaceContainerHigh: _lSurfaceDeeper,
    surfaceContainerHighest: _lSurfaceDeeper,
    surfaceDim: _lSurfaceSunken,
    surfaceBright: _lSurface,
    onSurfaceVariant: _lTextSecondary,
    inverseSurface: _lTextPrimary,
    onInverseSurface: _lSurface,
    outline: _lBorderStrong,
    outlineVariant: _lBorder,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: accent,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accentDark,
    onPrimary: Color(0xFF0B0B0E),
    primaryContainer: accentSoftDark,
    onPrimaryContainer: accentDark,
    inversePrimary: accent,
    secondary: _dTextSecondary,
    onSecondary: _dSurface,
    secondaryContainer: _dSurfaceSunken,
    onSecondaryContainer: _dTextPrimary,
    tertiary: accentDark,
    onTertiary: _dSurface,
    tertiaryContainer: accentSoftDark,
    onTertiaryContainer: accentDark,
    error: errorDark,
    onError: Color(0xFF0B0B0E),
    errorContainer: Color(0xFF3F1212),
    onErrorContainer: errorDark,
    surface: _dSurface,
    onSurface: _dTextPrimary,
    surfaceContainerLowest: _dSurface,
    surfaceContainerLow: _dSurfaceElevated,
    surfaceContainer: _dSurfaceSunken,
    surfaceContainerHigh: _dSurfaceDeeper,
    surfaceContainerHighest: _dSurfaceDeeper,
    surfaceDim: _dSurface,
    surfaceBright: _dSurfaceElevated,
    onSurfaceVariant: _dTextSecondary,
    inverseSurface: _dTextPrimary,
    onInverseSurface: _dSurface,
    outline: _dBorderStrong,
    outlineVariant: _dBorder,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: accentDark,
  );

  // ─────────────────────────────────────────────────────────
  //  BACKWARD-COMPAT ALIASES
  //  Existing widgets keep referencing these names. Each one resolves to
  //  a value from the spec above; new code should reach for
  //  `Theme.of(context).colorScheme` instead.
  // ─────────────────────────────────────────────────────────

  /// Brand accent. Mapped to the spec accent.
  static const Color primary = accent;
  static const Color primaryLight = accentDark;
  static const Color primaryContainer = accentSoft;
  static const Color onPrimaryContainer = accent;
  static const Color secondary = accent;
  static const Color secondaryContainer = accentSoft;
  static const Color onSecondaryContainer = accent;

  // Dark surfaces — kept so legacy `AppColors.bg*` references resolve.
  static const Color bgDeep = _dSurface;
  static const Color bgSurface = _dSurface;
  static const Color bgContainer = _dSurfaceElevated;
  static const Color bgContainerHigh = _dSurfaceSunken;
  static const Color bgContainerHighest = _dSurfaceDeeper;
  static const Color bgMid = _dSurfaceElevated;
  static const Color bgSurfaceDark = _dSurfaceElevated;

  static const Color bgLight = _lSurface;
  static const Color bgLightSurface = _lSurface;
  static const Color bgLightContainerLow = _lSurfaceElevated;
  static const Color bgLightContainer = _lSurfaceSunken;
  static const Color bgLightContainerHigh = _lSurfaceDeeper;
  static const Color bgLightContainerHighest = _lSurfaceDeeper;

  static const Color textPrimary = _dTextPrimary;
  static const Color textSecondary = _dTextSecondary;
  static const Color textHint = _dTextTertiary;
  static const Color textPrimaryLight = _lTextPrimary;
  static const Color textSecondaryLight = _lTextSecondary;
  static const Color textHintLight = _lTextTertiary;

  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color danger = error;

  static const Color outline = _lBorderStrong;
  static const Color outlineVariant = _lBorder;
  static const Color outlineDark = _dBorderStrong;
  static const Color outlineVariantDark = _dBorder;

  /// Legacy "glass" tokens. There are no glass surfaces in the 2026
  /// system — these alias to neutral hairline equivalents so old call
  /// sites still render correctly. Do not use in new code.
  static const Color glassWhite = _lSurfaceSunken;
  static const Color glassBorder = _lBorder;
  static const Color glassBorderSubtle = _lBorder;
  static const Color glassFill = _lSurfaceElevated;
  static const Color glassFillLight = _lSurface;
  static const Color glassPrimary = accent;
  static const Color glassPrimaryLight = accentDark;
}
