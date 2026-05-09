import 'package:flutter/material.dart';

/// Listd 2027 design tokens.
///
/// Warm neutrals + two accents: `flame` (vibrant emphasis) and `oat`
/// (muted support). Functional state colors are scoped to 6 px dots only.
/// See `listd_2027_design_spec.md` §3.3.
///
/// Old 2026 token names (`primary`, `bg*`, `glass*`, …) are kept as
/// backward-compat aliases that resolve to the corresponding 2027 token,
/// so existing widgets pick up the new look automatically. New code
/// should reach for `Theme.of(context).colorScheme` or the `ListdSurfaces`
/// extension instead.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  //  ACCENTS — exactly two: flame (vibrant) + oat (muted).
  // ─────────────────────────────────────────────────────────

  /// Vibrant flame — selection, focus ring, primary action, today.
  static const Color flame = Color(0xFFFF6B35);

  /// Dark-mode flame — adjusted for contrast on warm-ink surfaces.
  static const Color flameDark = Color(0xFFFF8A5C);

  /// Selected row fill / today's calendar cell (light).
  static const Color flameSoft = Color(0xFFFFE4D6);

  /// Selected row fill / today's calendar cell (dark).
  static const Color flameSoftDark = Color(0xFF3D241A);

  /// Muted oat — counts, secondary chips, completed-state dot (light).
  static const Color oat = Color(0xFFA89878);

  /// Muted oat (dark).
  static const Color oatDark = Color(0xFFC4B294);

  /// Tag chip fill / hover row fill (light).
  static const Color oatSoft = Color(0xFFF1EAE0);

  /// Tag chip fill / hover row fill (dark).
  static const Color oatSoftDark = Color(0xFF2A2620);

  // ─────────────────────────────────────────────────────────
  //  WARM NEUTRALS — the main color story.
  //  Surface roles live on the `ListdSurfaces` extension; these are
  //  the raw token values used to build them.
  // ─────────────────────────────────────────────────────────

  // Light surfaces.
  static const Color _lAmbient = Color(0xFFF6F1EA);
  static const Color _lCanvas = Color(0xFFFFFFFF);
  static const Color _lPanel = Color(0xFFFBF6EE);
  static const Color _lChip = Color(0xFFF1EAE0);

  // Light text + lines.
  static const Color _lTextPrimary = Color(0xFF1B1A18);
  static const Color _lTextSecondary = Color(0xFF5C564E);
  static const Color _lTextTertiary = Color(0xFF9A938B);
  static const Color _lBorder = Color(0xFFE6DFD4);
  static const Color _lBorderStrong = Color(0xFFD6CDC0);
  static const Color _lDivider = Color(0xFFEFEAE0);

  // Dark surfaces.
  static const Color _dAmbient = Color(0xFF0E0C10);
  static const Color _dCanvas = Color(0xFF1A171F);
  static const Color _dPanel = Color(0xFF16131A);
  static const Color _dCard = Color(0xFF1F1B25);
  static const Color _dChip = Color(0xFF26212C);

  // Dark text + lines.
  static const Color _dTextPrimary = Color(0xFFF4EFE7);
  static const Color _dTextSecondary = Color(0xFFA8A199);
  static const Color _dTextTertiary = Color(0xFF6E6862);
  static const Color _dBorder = Color(0xFF2C2730);
  static const Color _dBorderStrong = Color(0xFF3A343F);
  static const Color _dDivider = Color(0xFF221F26);

  // ─────────────────────────────────────────────────────────
  //  AMBIENT BACKPLATE STOPS
  //  Soft radial gradient corners. See `lib/theme/gradients.dart` →
  //  `AppBackplate`.
  // ─────────────────────────────────────────────────────────

  static const Color ambientLightStartTopLeft = Color(0xFFF6E8D2);
  static const Color ambientLightStartBottomRight = Color(0xFFEAD8E5);
  static const Color ambientDarkStartTopLeft = Color(0xFF2A1F2E);
  static const Color ambientDarkStartBottomRight = Color(0xFF1A2230);

  // ─────────────────────────────────────────────────────────
  //  FUNCTIONAL — used only as 6 px dots inside state pills.
  //  Never on type or selection.
  // ─────────────────────────────────────────────────────────

  static const Color success = Color(0xFF3F8F4F);
  static const Color successDark = Color(0xFF5BB070);
  static const Color warning = Color(0xFFC97C2C);
  static const Color warningDark = Color(0xFFE09A50);
  static const Color error = Color(0xFFB84A3A);
  static const Color errorDark = Color(0xFFD8694F);

  // ─────────────────────────────────────────────────────────
  //  SHADOW INK
  //  Warm-tinted in light mode; pure black in dark mode.
  // ─────────────────────────────────────────────────────────

  static const Color shadowInk = Color(0xFF1C1610);

  // ─────────────────────────────────────────────────────────
  //  COLOR SCHEMES — explicit, no fromSeed.
  // ─────────────────────────────────────────────────────────

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: flame,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: flameSoft,
    onPrimaryContainer: flame,
    inversePrimary: flameDark,
    secondary: oat,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: oatSoft,
    onSecondaryContainer: _lTextPrimary,
    tertiary: oat,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: oatSoft,
    onTertiaryContainer: _lTextPrimary,
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8DAD3),
    onErrorContainer: error,
    surface: _lCanvas,
    onSurface: _lTextPrimary,
    surfaceContainerLowest: _lCanvas,
    surfaceContainerLow: _lPanel,
    surfaceContainer: _lAmbient,
    surfaceContainerHigh: _lChip,
    surfaceContainerHighest: _lDivider,
    surfaceDim: _lAmbient,
    surfaceBright: _lCanvas,
    onSurfaceVariant: _lTextSecondary,
    inverseSurface: _lTextPrimary,
    onInverseSurface: _lCanvas,
    outline: _lBorderStrong,
    outlineVariant: _lBorder,
    shadow: shadowInk,
    scrim: Color(0xFF1C1610),
    surfaceTint: flame,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: flameDark,
    onPrimary: Color(0xFF1F1208),
    primaryContainer: flameSoftDark,
    onPrimaryContainer: flameDark,
    inversePrimary: flame,
    secondary: oatDark,
    onSecondary: Color(0xFF1F1B12),
    secondaryContainer: oatSoftDark,
    onSecondaryContainer: _dTextPrimary,
    tertiary: oatDark,
    onTertiary: Color(0xFF1F1B12),
    tertiaryContainer: oatSoftDark,
    onTertiaryContainer: _dTextPrimary,
    error: errorDark,
    onError: Color(0xFF1F0E0B),
    errorContainer: Color(0xFF3F1D17),
    onErrorContainer: errorDark,
    surface: _dCanvas,
    onSurface: _dTextPrimary,
    surfaceContainerLowest: _dAmbient,
    surfaceContainerLow: _dPanel,
    surfaceContainer: _dCanvas,
    surfaceContainerHigh: _dCard,
    surfaceContainerHighest: _dDivider,
    surfaceDim: _dAmbient,
    surfaceBright: _dCard,
    onSurfaceVariant: _dTextSecondary,
    inverseSurface: _dTextPrimary,
    onInverseSurface: _dCanvas,
    outline: _dBorderStrong,
    outlineVariant: _dBorder,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: flameDark,
  );

  // ─────────────────────────────────────────────────────────
  //  BACKWARD-COMPAT ALIASES
  //  The 2026 system referenced these names everywhere. Each one
  //  resolves to the equivalent 2027 token so call sites keep
  //  compiling and visually pick up the new look automatically.
  //  New code must use `Theme.of(context).colorScheme` or
  //  `ListdSurfaces` instead — these aliases will be removed in
  //  P7 alongside the `AppGradients` purge.
  // ─────────────────────────────────────────────────────────

  /// Mapped to 2027 flame so the 2026 indigo brand alias resolves
  /// to the new accent.
  static const Color accent = flame;
  static const Color accentDark = flameDark;
  static const Color accentSoft = flameSoft;
  static const Color accentSoftDark = flameSoftDark;

  static const Color primary = flame;
  static const Color primaryLight = flameDark;
  static const Color primaryContainer = flameSoft;
  static const Color onPrimaryContainer = flame;
  static const Color secondary = oat;
  static const Color secondaryContainer = oatSoft;
  static const Color onSecondaryContainer = _lTextPrimary;

  // Dark-surface aliases.
  static const Color bgDeep = _dAmbient;
  static const Color bgSurface = _dCanvas;
  static const Color bgContainer = _dPanel;
  static const Color bgContainerHigh = _dCard;
  static const Color bgContainerHighest = _dChip;
  static const Color bgMid = _dPanel;
  static const Color bgSurfaceDark = _dPanel;

  // Light-surface aliases.
  static const Color bgLight = _lAmbient;
  static const Color bgLightSurface = _lCanvas;
  static const Color bgLightContainerLow = _lPanel;
  static const Color bgLightContainer = _lChip;
  static const Color bgLightContainerHigh = _lChip;
  static const Color bgLightContainerHighest = _lDivider;

  static const Color textPrimary = _dTextPrimary;
  static const Color textSecondary = _dTextSecondary;
  static const Color textHint = _dTextTertiary;
  static const Color textPrimaryLight = _lTextPrimary;
  static const Color textSecondaryLight = _lTextSecondary;
  static const Color textHintLight = _lTextTertiary;

  static const Color errorContainer = Color(0xFFF8DAD3);
  static const Color danger = error;

  static const Color outline = _lBorderStrong;
  static const Color outlineVariant = _lBorder;
  static const Color outlineDark = _dBorderStrong;
  static const Color outlineVariantDark = _dBorder;

  /// Legacy "glass" tokens. There are no glass surfaces in the 2027
  /// system — these alias to the new neutrals so old call sites still
  /// render correctly. Do not use in new code.
  static const Color glassWhite = _lChip;
  static const Color glassBorder = _lBorder;
  static const Color glassBorderSubtle = _lBorder;
  static const Color glassFill = _lPanel;
  static const Color glassFillLight = _lCanvas;
  static const Color glassPrimary = flame;
  static const Color glassPrimaryLight = flameDark;
}
