import 'package:flutter/material.dart';

/// Stitch indigo design tokens for Listd.
///
/// Every value below is sourced verbatim from the design tokens in
/// `stitch_listd_indigo_task_manager/listd*/DESIGN.md`. Do not invent new
/// hex literals for product surfaces — extend the [ColorScheme] returned
/// by [lightScheme] / [darkScheme] instead so the rest of the app keeps
/// referencing colors via `Theme.of(context).colorScheme`.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  //  LIGHT THEME (Stitch: listd/DESIGN.md)
  // ─────────────────────────────────────────────────────────

  static const Color _lPrimary = Color(0xFF1A146B);
  static const Color _lOnPrimary = Color(0xFFFFFFFF);
  static const Color _lPrimaryContainer = Color(0xFF312E81);
  static const Color _lOnPrimaryContainer = Color(0xFF9C9AF4);
  static const Color _lInversePrimary = Color(0xFFC3C0FF);

  static const Color _lSecondary = Color(0xFF4648D4);
  static const Color _lOnSecondary = Color(0xFFFFFFFF);
  static const Color _lSecondaryContainer = Color(0xFF6063EE);
  static const Color _lOnSecondaryContainer = Color(0xFFFFFBFF);

  static const Color _lTertiary = Color(0xFF172245);
  static const Color _lOnTertiary = Color(0xFFFFFFFF);
  static const Color _lTertiaryContainer = Color(0xFF2D385C);
  static const Color _lOnTertiaryContainer = Color(0xFF97A2CC);

  static const Color _lError = Color(0xFFBA1A1A);
  static const Color _lOnError = Color(0xFFFFFFFF);
  static const Color _lErrorContainer = Color(0xFFFFDAD6);
  static const Color _lOnErrorContainer = Color(0xFF93000A);

  static const Color _lSurface = Color(0xFFF7F9FB);
  static const Color _lOnSurface = Color(0xFF191C1E);
  static const Color _lOnSurfaceVariant = Color(0xFF474651);
  static const Color _lInverseSurface = Color(0xFF2D3133);
  static const Color _lInverseOnSurface = Color(0xFFEFF1F3);
  static const Color _lOutline = Color(0xFF777682);
  static const Color _lOutlineVariant = Color(0xFFC8C5D3);
  static const Color _lShadow = Color(0xFF000000);
  static const Color _lScrim = Color(0xFF000000);
  static const Color _lSurfaceTint = Color(0xFF5654A8);

  static const Color lSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lSurfaceContainerLow = Color(0xFFF2F4F6);
  static const Color lSurfaceContainer = Color(0xFFECEEF0);
  static const Color lSurfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color lSurfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color lSurfaceDim = Color(0xFFD8DADC);
  static const Color lSurfaceBright = Color(0xFFF7F9FB);

  // ─────────────────────────────────────────────────────────
  //  DARK THEME (Stitch: listd_dark/DESIGN.md)
  // ─────────────────────────────────────────────────────────

  static const Color _dPrimary = Color(0xFFC3C0FF);
  static const Color _dOnPrimary = Color(0xFF272377);
  static const Color _dPrimaryContainer = Color(0xFF312E81);
  static const Color _dOnPrimaryContainer = Color(0xFF9C9AF4);
  static const Color _dInversePrimary = Color(0xFF5654A8);

  static const Color _dSecondary = Color(0xFFC0C1FF);
  static const Color _dOnSecondary = Color(0xFF1000A9);
  static const Color _dSecondaryContainer = Color(0xFF3131C0);
  static const Color _dOnSecondaryContainer = Color(0xFFB0B2FF);

  static const Color _dTertiary = Color(0xFFFFB688);
  static const Color _dOnTertiary = Color(0xFF512400);
  static const Color _dTertiaryContainer = Color(0xFF5F2B00);
  static const Color _dOnTertiaryContainer = Color(0xFFDE915E);

  static const Color _dError = Color(0xFFFFB4AB);
  static const Color _dOnError = Color(0xFF690005);
  static const Color _dErrorContainer = Color(0xFF93000A);
  static const Color _dOnErrorContainer = Color(0xFFFFDAD6);

  static const Color _dSurface = Color(0xFF0B1326);
  static const Color _dOnSurface = Color(0xFFDAE2FD);
  static const Color _dOnSurfaceVariant = Color(0xFFC8C5D3);
  static const Color _dInverseSurface = Color(0xFFDAE2FD);
  static const Color _dInverseOnSurface = Color(0xFF283044);
  static const Color _dOutline = Color(0xFF918F9C);
  static const Color _dOutlineVariant = Color(0xFF474651);
  static const Color _dShadow = Color(0xFF000000);
  static const Color _dScrim = Color(0xFF000000);
  static const Color _dSurfaceTint = Color(0xFFC3C0FF);

  static const Color dSurfaceContainerLowest = Color(0xFF060E20);
  static const Color dSurfaceContainerLow = Color(0xFF131B2E);
  static const Color dSurfaceContainer = Color(0xFF171F33);
  static const Color dSurfaceContainerHigh = Color(0xFF222A3D);
  static const Color dSurfaceContainerHighest = Color(0xFF2D3449);
  static const Color dSurfaceDim = Color(0xFF0B1326);
  static const Color dSurfaceBright = Color(0xFF31394D);

  // ─────────────────────────────────────────────────────────
  //  SCHEMES — explicit, no fromSeed.
  // ─────────────────────────────────────────────────────────

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _lPrimary,
    onPrimary: _lOnPrimary,
    primaryContainer: _lPrimaryContainer,
    onPrimaryContainer: _lOnPrimaryContainer,
    inversePrimary: _lInversePrimary,
    secondary: _lSecondary,
    onSecondary: _lOnSecondary,
    secondaryContainer: _lSecondaryContainer,
    onSecondaryContainer: _lOnSecondaryContainer,
    tertiary: _lTertiary,
    onTertiary: _lOnTertiary,
    tertiaryContainer: _lTertiaryContainer,
    onTertiaryContainer: _lOnTertiaryContainer,
    error: _lError,
    onError: _lOnError,
    errorContainer: _lErrorContainer,
    onErrorContainer: _lOnErrorContainer,
    surface: _lSurface,
    onSurface: _lOnSurface,
    surfaceContainerLowest: lSurfaceContainerLowest,
    surfaceContainerLow: lSurfaceContainerLow,
    surfaceContainer: lSurfaceContainer,
    surfaceContainerHigh: lSurfaceContainerHigh,
    surfaceContainerHighest: lSurfaceContainerHighest,
    surfaceDim: lSurfaceDim,
    surfaceBright: lSurfaceBright,
    onSurfaceVariant: _lOnSurfaceVariant,
    inverseSurface: _lInverseSurface,
    onInverseSurface: _lInverseOnSurface,
    outline: _lOutline,
    outlineVariant: _lOutlineVariant,
    shadow: _lShadow,
    scrim: _lScrim,
    surfaceTint: _lSurfaceTint,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _dPrimary,
    onPrimary: _dOnPrimary,
    primaryContainer: _dPrimaryContainer,
    onPrimaryContainer: _dOnPrimaryContainer,
    inversePrimary: _dInversePrimary,
    secondary: _dSecondary,
    onSecondary: _dOnSecondary,
    secondaryContainer: _dSecondaryContainer,
    onSecondaryContainer: _dOnSecondaryContainer,
    tertiary: _dTertiary,
    onTertiary: _dOnTertiary,
    tertiaryContainer: _dTertiaryContainer,
    onTertiaryContainer: _dOnTertiaryContainer,
    error: _dError,
    onError: _dOnError,
    errorContainer: _dErrorContainer,
    onErrorContainer: _dOnErrorContainer,
    surface: _dSurface,
    onSurface: _dOnSurface,
    surfaceContainerLowest: dSurfaceContainerLowest,
    surfaceContainerLow: dSurfaceContainerLow,
    surfaceContainer: dSurfaceContainer,
    surfaceContainerHigh: dSurfaceContainerHigh,
    surfaceContainerHighest: dSurfaceContainerHighest,
    surfaceDim: dSurfaceDim,
    surfaceBright: dSurfaceBright,
    onSurfaceVariant: _dOnSurfaceVariant,
    inverseSurface: _dInverseSurface,
    onInverseSurface: _dInverseOnSurface,
    outline: _dOutline,
    outlineVariant: _dOutlineVariant,
    shadow: _dShadow,
    scrim: _dScrim,
    surfaceTint: _dSurfaceTint,
  );

  // ─────────────────────────────────────────────────────────
  //  BACKWARD-COMPAT ALIASES
  //  Existing widgets still reference these names; they all resolve to
  //  the explicit token values above. New code should reach for
  //  `Theme.of(context).colorScheme` instead.
  // ─────────────────────────────────────────────────────────

  static const Color primary = _lPrimary;
  static const Color primaryLight = _dPrimary;
  static const Color primaryContainer = _lPrimaryContainer;
  static const Color onPrimaryContainer = _lOnPrimaryContainer;
  static const Color secondary = _lSecondary;
  static const Color secondaryContainer = _lSecondaryContainer;
  static const Color onSecondaryContainer = _lOnSecondaryContainer;

  static const Color bgDeep = _dSurface;
  static const Color bgSurface = dSurfaceContainerLow;
  static const Color bgContainer = dSurfaceContainer;
  static const Color bgContainerHigh = dSurfaceContainerHigh;
  static const Color bgContainerHighest = dSurfaceContainerHighest;
  static const Color bgMid = Color(0xFF0E1030);
  static const Color bgSurfaceDark = Color(0xFF131440);

  static const Color bgLight = _lSurface;
  static const Color bgLightSurface = _lSurface;
  static const Color bgLightContainerLow = lSurfaceContainerLow;
  static const Color bgLightContainer = lSurfaceContainer;
  static const Color bgLightContainerHigh = lSurfaceContainerHigh;
  static const Color bgLightContainerHighest = lSurfaceContainerHighest;

  static const Color textPrimary = _dOnSurface;
  static const Color textSecondary = _dOnSurfaceVariant;
  static const Color textHint = _dOutline;
  static const Color textPrimaryLight = _lOnSurface;
  static const Color textSecondaryLight = _lOnSurfaceVariant;
  static const Color textHintLight = _lOutline;

  static const Color error = _lError;
  static const Color errorDark = _dError;
  static const Color errorContainer = _dErrorContainer;
  static const Color danger = _lError;
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFCA28);
  static const Color warningDark = _dTertiary;

  static const Color outline = _lOutline;
  static const Color outlineVariant = _lOutlineVariant;
  static const Color outlineDark = _dOutline;
  static const Color outlineVariantDark = _dOutlineVariant;

  /// Glass-effect aliases retained so the existing `glass_*` widgets keep
  /// rendering until they are replaced with Material 3 surfaces. New code
  /// should not reference these; use `colorScheme.surfaceContainer` etc.
  static const Color glassWhite = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color glassBorderSubtle = Color(0x1AFFFFFF);
  static const Color glassFill = Color(0x0DFFFFFF);
  static const Color glassFillLight = Color(0x14FFFFFF);
  static const Color glassPrimary = Color(0xFF5C6BC0);
  static const Color glassPrimaryLight = Color(0xFF7986CB);
}
