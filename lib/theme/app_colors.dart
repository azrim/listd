import 'package:flutter/material.dart';

/// Listd 2027 · Indigo Edition design tokens.
///
/// Cool, indigo-tinted neutrals. Indigo is the primary accent (selection,
/// focus, primary action, today). Amber is the single co-accent and is
/// scoped to **stars / importance state only**. Functional state colors
/// (success / warning / error) are scoped to 6 px state-pill dots only.
///
/// The palette is derived in OKLCH so light and dark steps share the same
/// hue/chroma curves and read with equal perceived weight. The sRGB
/// equivalents are committed below; see `docs/redesign/2027-indigo/02_tokens.md`
/// for the OKLCH source values.
///
/// Old token names (`flame`, `flameSoft`, `oat`, `oatSoft`, `bgDeep`,
/// `bgLight`, `glassWhite`, …) ship as `@Deprecated` aliases that point
/// at their indigo equivalents so existing widgets keep compiling and
/// pick up the new look automatically. New code should reach for
/// `Theme.of(context).colorScheme` or the `ListdSurfaces` extension.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  //  INDIGO scale — primary brand + selection.
  // ─────────────────────────────────────────────────────────

  static const Color indigo50 = Color(0xFFF0F1FF);
  static const Color indigo100 = Color(0xFFE0E2FF);
  static const Color indigo200 = Color(0xFFC2C5FF);
  static const Color indigo300 = Color(0xFFA0A2FA);
  static const Color indigo400 = Color(0xFF7376F8);
  static const Color indigo500 = Color(0xFF5A52E8);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);
  static const Color indigo950 = Color(0xFF1E1B4B);

  // ─────────────────────────────────────────────────────────
  //  SLATE scale — neutrals (cool, lightly indigo-tinted).
  // ─────────────────────────────────────────────────────────

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF0B1224);

  // ─────────────────────────────────────────────────────────
  //  AMBER scale — single co-accent, stars only.
  // ─────────────────────────────────────────────────────────

  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);

  /// Star fill / "Important" smart-list icon. Light theme.
  static const Color star = amber400;

  /// Star fill / "Important" smart-list icon. Dark theme.
  static const Color starDark = amber300;

  // ─────────────────────────────────────────────────────────
  //  FUNCTIONAL — scoped to 6 px state-pill dots only.
  //  Never on type, surfaces, or selection.
  // ─────────────────────────────────────────────────────────

  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color successDark = Color(0xFF34D399); // emerald-400
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color warningDark = Color(0xFFFBBF24); // amber-400
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color errorDark = Color(0xFFF87171); // red-400

  // ─────────────────────────────────────────────────────────
  //  PRIVATE SEMANTIC — light + dark surface roles.
  //  These compose the public ColorScheme below and the
  //  ListdSurfaces extension in app_theme.dart.
  // ─────────────────────────────────────────────────────────

  // Light surfaces.
  static const Color _lAmbient = slate50;
  static const Color _lCanvas = Color(0xFFFFFFFF);
  static const Color _lPanel = slate50;
  static const Color _lChip = slate100;

  // Light text + lines.
  static const Color _lTextPrimary = slate900;
  static const Color _lTextSecondary = slate500;
  static const Color _lTextTertiary = slate400;
  static const Color _lBorder = slate200;
  static const Color _lDivider = slate100;

  // Dark surfaces.
  static const Color _dAmbient = slate950;
  static const Color _dCanvas = slate900;
  static const Color _dPanel = slate900;
  static const Color _dCard = slate800;
  static const Color _dChip = slate700;

  // Dark text + lines.
  static const Color _dTextPrimary = slate50;
  static const Color _dTextSecondary = slate400;
  static const Color _dTextTertiary = slate500;
  static const Color _dBorder = slate700;
  static const Color _dDivider = slate800;

  // ─────────────────────────────────────────────────────────
  //  AMBIENT BACKPLATE STOPS
  //  Soft radial gradient corners. See lib/theme/gradients.dart.
  //  Light: indigo + pink wash. Dark: indigo + slate.
  // ─────────────────────────────────────────────────────────

  /// Light-theme top-left corner (indigo wash).
  static const Color ambientLightStartTopLeft = Color(0xFFE0E2FF); // indigo-100
  /// Light-theme bottom-right corner (faint pink-300).
  static const Color ambientLightStartBottomRight = Color(0xFFF0ABFC);

  /// Dark-theme top-left corner.
  static const Color ambientDarkStartTopLeft = indigo900;

  /// Dark-theme bottom-right corner.
  static const Color ambientDarkStartBottomRight = slate800;

  // ─────────────────────────────────────────────────────────
  //  SHADOW INK — slate-tinted in light mode; pure black in dark mode.
  // ─────────────────────────────────────────────────────────

  static const Color shadowInk = slate900;

  // ─────────────────────────────────────────────────────────
  //  COLOR SCHEMES — explicit, no fromSeed.
  // ─────────────────────────────────────────────────────────

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: indigo600,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: indigo50,
    onPrimaryContainer: indigo700,
    inversePrimary: indigo300,
    secondary: amber400,
    onSecondary: indigo950,
    secondaryContainer: Color(0xFFFEF3C7), // amber-100
    onSecondaryContainer: Color(0xFF78350F), // amber-900
    tertiary: slate500,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: slate100,
    onTertiaryContainer: slate700,
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2), // red-100
    onErrorContainer: Color(0xFF7F1D1D), // red-900
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
    inverseSurface: slate900,
    onInverseSurface: slate50,
    outline: _lBorder,
    outlineVariant: _lDivider,
    shadow: shadowInk,
    scrim: shadowInk,
    surfaceTint: indigo600,
  );

  // 40% indigo900 → ARGB 0x66312E81. Used for dark `primaryContainer`
  // and dark `accent-soft` (selected row fill, today cell).
  static const Color _accentSoftDark = Color(0x66312E81);

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: indigo400,
    onPrimary: indigo950,
    primaryContainer: _accentSoftDark,
    onPrimaryContainer: indigo200,
    inversePrimary: indigo700,
    secondary: amber300,
    onSecondary: indigo950,
    secondaryContainer: Color(0xFF422006), // amber-950ish
    onSecondaryContainer: amber300,
    tertiary: slate400,
    onTertiary: slate950,
    tertiaryContainer: slate800,
    onTertiaryContainer: slate200,
    error: errorDark,
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B), // red-800
    onErrorContainer: Color(0xFFFECACA), // red-200
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
    inverseSurface: slate50,
    onInverseSurface: slate900,
    outline: _dBorder,
    outlineVariant: _dDivider,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: indigo400,
  );

  // ─────────────────────────────────────────────────────────
  //  DEPRECATED ALIASES
  //
  //  Names from the 2027 warm-cream system. Each one resolves to
  //  the equivalent indigo/slate token so existing call sites keep
  //  compiling and visually pick up the new look automatically.
  //  Will be removed in PR C alongside the editor + empty-state
  //  cleanup. New code must use `Theme.of(context).colorScheme` or
  //  `ListdSurfaces` instead.
  // ─────────────────────────────────────────────────────────

  // Flame / oat accent aliases.

  @Deprecated('Use ColorScheme.primary or AppColors.indigo600.')
  static const Color flame = indigo600;

  @Deprecated('Use ColorScheme.primary (dark) or AppColors.indigo400.')
  static const Color flameDark = indigo400;

  @Deprecated('Use ColorScheme.primaryContainer or AppColors.indigo50.')
  static const Color flameSoft = indigo50;

  @Deprecated('Use ColorScheme.primaryContainer (dark).')
  static const Color flameSoftDark = _accentSoftDark;

  @Deprecated('Use ColorScheme.tertiary or AppColors.slate500.')
  static const Color oat = slate500;

  @Deprecated('Use ColorScheme.tertiary (dark) or AppColors.slate400.')
  static const Color oatDark = slate400;

  @Deprecated('Use ColorScheme.surfaceContainerHigh or AppColors.slate100.')
  static const Color oatSoft = slate100;

  @Deprecated(
    'Use ColorScheme.surfaceContainerHigh (dark) or AppColors.slate700.',
  )
  static const Color oatSoftDark = slate700;

  // 2026 brand aliases (still referenced by some legacy widgets).

  @Deprecated('Use ColorScheme.primary.')
  static const Color accent = indigo600;

  @Deprecated('Use ColorScheme.primary (dark).')
  static const Color accentDark = indigo400;

  @Deprecated('Use ColorScheme.primaryContainer.')
  static const Color accentSoft = indigo50;

  @Deprecated('Use ColorScheme.primaryContainer (dark).')
  static const Color accentSoftDark = _accentSoftDark;

  @Deprecated('Use ColorScheme.primary.')
  static const Color primary = indigo600;

  @Deprecated('Use ColorScheme.primary (dark).')
  static const Color primaryLight = indigo400;

  @Deprecated('Use ColorScheme.primaryContainer.')
  static const Color primaryContainer = indigo50;

  @Deprecated('Use ColorScheme.onPrimaryContainer.')
  static const Color onPrimaryContainer = indigo700;

  @Deprecated('Use ColorScheme.tertiary.')
  static const Color secondary = slate500;

  @Deprecated('Use ColorScheme.tertiaryContainer.')
  static const Color secondaryContainer = slate100;

  @Deprecated('Use ColorScheme.onTertiaryContainer.')
  static const Color onSecondaryContainer = _lTextPrimary;

  // Surface aliases — dark.

  @Deprecated('Use ColorScheme.surfaceContainerLowest or AppColors.slate950.')
  static const Color bgDeep = _dAmbient;

  @Deprecated('Use ColorScheme.surface or AppColors.slate900.')
  static const Color bgSurface = _dCanvas;

  @Deprecated('Use ColorScheme.surfaceContainerLow or AppColors.slate900.')
  static const Color bgContainer = _dPanel;

  @Deprecated('Use ColorScheme.surfaceContainerHigh or AppColors.slate800.')
  static const Color bgContainerHigh = _dCard;

  @Deprecated('Use ColorScheme.surfaceContainerHighest or AppColors.slate700.')
  static const Color bgContainerHighest = _dChip;

  @Deprecated('Use ColorScheme.surfaceContainerLow.')
  static const Color bgMid = _dPanel;

  @Deprecated('Use ColorScheme.surfaceContainerLow.')
  static const Color bgSurfaceDark = _dPanel;

  // Surface aliases — light.

  @Deprecated('Use ColorScheme.surfaceContainer or AppColors.slate50.')
  static const Color bgLight = _lAmbient;

  @Deprecated('Use ColorScheme.surface (light) or AppColors.slate50.')
  static const Color bgLightSurface = _lCanvas;

  @Deprecated('Use ColorScheme.surfaceContainerLow or AppColors.slate50.')
  static const Color bgLightContainerLow = _lPanel;

  @Deprecated('Use ColorScheme.surfaceContainerHigh or AppColors.slate100.')
  static const Color bgLightContainer = _lChip;

  @Deprecated('Use ColorScheme.surfaceContainerHigh or AppColors.slate100.')
  static const Color bgLightContainerHigh = _lChip;

  @Deprecated('Use ColorScheme.surfaceContainerHighest or AppColors.slate100.')
  static const Color bgLightContainerHighest = _lDivider;

  // Text + outline aliases.

  @Deprecated('Use ColorScheme.onSurface (dark) or AppColors.slate50.')
  static const Color textPrimary = _dTextPrimary;

  @Deprecated('Use ColorScheme.onSurfaceVariant (dark) or AppColors.slate400.')
  static const Color textSecondary = _dTextSecondary;

  @Deprecated('Use ColorScheme.outline (dark) or AppColors.slate500.')
  static const Color textHint = _dTextTertiary;

  @Deprecated('Use ColorScheme.onSurface (light) or AppColors.slate900.')
  static const Color textPrimaryLight = _lTextPrimary;

  @Deprecated('Use ColorScheme.onSurfaceVariant (light) or AppColors.slate500.')
  static const Color textSecondaryLight = _lTextSecondary;

  @Deprecated('Use ColorScheme.outline (light) or AppColors.slate400.')
  static const Color textHintLight = _lTextTertiary;

  @Deprecated('Use ColorScheme.errorContainer.')
  static const Color errorContainer = Color(0xFFFEE2E2);

  @Deprecated('Use ColorScheme.error.')
  static const Color danger = error;

  @Deprecated('Use ColorScheme.outline (light).')
  static const Color outline = _lBorder;

  @Deprecated('Use ColorScheme.outlineVariant (light).')
  static const Color outlineVariant = _lDivider;

  @Deprecated('Use ColorScheme.outline (dark).')
  static const Color outlineDark = _dBorder;

  @Deprecated('Use ColorScheme.outlineVariant (dark).')
  static const Color outlineVariantDark = _dDivider;

  // Legacy "glass" tokens — retained as aliases only.
  // No glass surfaces exist in the indigo system.

  @Deprecated('Glass surfaces removed. Use ColorScheme.surfaceContainerHigh.')
  static const Color glassWhite = _lChip;

  @Deprecated('Glass surfaces removed. Use ColorScheme.outlineVariant.')
  static const Color glassBorder = _lBorder;

  @Deprecated('Glass surfaces removed. Use ColorScheme.outlineVariant.')
  static const Color glassBorderSubtle = _lBorder;

  @Deprecated('Glass surfaces removed. Use ColorScheme.surfaceContainerLow.')
  static const Color glassFill = _lPanel;

  @Deprecated('Glass surfaces removed. Use ColorScheme.surface.')
  static const Color glassFillLight = _lCanvas;

  @Deprecated('Glass surfaces removed. Use ColorScheme.primary.')
  static const Color glassPrimary = indigo600;

  @Deprecated('Glass surfaces removed. Use ColorScheme.primary (dark).')
  static const Color glassPrimaryLight = indigo400;
}
