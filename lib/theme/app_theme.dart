import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'spring.dart';

/// Listd 2027 · Indigo Edition theme.
///
/// Two faces (Inter + Newsreader), one indigo primary, slate neutrals,
/// amber stars, soft slate-tinted shadows, single spring (named
/// calibrations live on `AppMotion`). All metrics derive from the 4 px
/// base grid.
///
/// Component metrics:
///   - control radius: 10 px
///   - card radius:    14 px
///   - panel radius:   20 px
///   - sheet radius:   24 px
///   - chip radius:    999 px
///   - control height: 36 px (cozy) / 32 px (compact)
///   - row height:     56 px (cozy) / 44 px (compact)
class AppTheme {
  AppTheme._();

  static const double controlRadius = 10;
  static const double cardRadius = 14;
  static const double panelRadius = 20;
  static const double sheetRadius = 24;
  static const double pillRadius = 999;
  static const double controlHeight = 36;
  static const double taskCardHeight = 56;

  static ThemeData get darkTheme => _buildTheme(AppColors.darkScheme);
  static ThemeData get lightTheme => _buildTheme(AppColors.lightScheme);

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      // Scaffold/canvas are transparent so the AppBackplate shows through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      textTheme: _buildTextTheme(
        scheme.onSurface,
        scheme.onSurfaceVariant,
        scheme.outline,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          height: 26 / 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.18,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 20),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          height: 22 / 15,
          color: scheme.outline,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          height: 18 / 13,
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),

      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 18),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 20 / 14,
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          height: 26 / 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.18,
          color: scheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          height: 22 / 15,
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
        circularTrackColor: scheme.surfaceContainer,
        linearMinHeight: 2,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.slate100 : AppColors.slate700,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: scheme.outline, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.all(scheme.outlineVariant),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          height: 16 / 12,
          color: scheme.onInverseSurface,
        ),
      ),

      cardColor: scheme.surface,
      hintColor: scheme.outline,
      shadowColor: scheme.shadow,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: scheme.surfaceContainer,
      visualDensity: VisualDensity.standard,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      extensions: <ThemeExtension<dynamic>>[
        _surfacesFor(scheme),
        ListdMotion.standard,
        _typographyFor(scheme.onSurface, scheme.onSurfaceVariant),
      ],
    );
  }

  static ListdSurfaces _surfacesFor(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return ListdSurfaces(
      ambient: isLight ? AppColors.slate50 : AppColors.slate950,
      canvas: scheme.surface,
      // Dark stack steps: panel (sidebar) slate-900 → canvas slate-800
      // → card slate-700 → chip slate-600. Each step is one slate
      // stop brighter so the expanded task card / hovered chips
      // visibly pop above the canvas surface.
      panel: isLight ? AppColors.slate50 : AppColors.slate900,
      card: isLight ? const Color(0xFFFFFFFF) : AppColors.slate700,
      chip: isLight ? AppColors.slate100 : AppColors.slate600,
      sidebar: isLight ? AppColors.slate50 : AppColors.slate900,
      detailPanel: isLight ? AppColors.slate50 : AppColors.slate900,
      surfaceTint: scheme.primary,
      // Soft slate-ink shadows — warm tinting removed so shadows read
      // as cool, even on indigo washes.
      shadowSm: isLight
          ? const BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          : const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
      shadowMd: isLight
          ? const BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 20,
              offset: Offset(0, 6),
            )
          : const BoxShadow(
              color: Color(0x80000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
      shadowLg: isLight
          ? const BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 48,
              offset: Offset(0, 24),
            )
          : const BoxShadow(
              color: Color(0xB3000000),
              blurRadius: 48,
              offset: Offset(0, 24),
            ),
    );
  }

  static ListdTypography _typographyFor(
    Color textPrimary,
    Color textSecondary,
  ) {
    return ListdTypography(
      // Newsreader is loaded lazily via google_fonts; in P4 it'll be
      // pre-warmed at boot to avoid layout flash.
      displaySerif: GoogleFonts.newsreader(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.72,
        color: textPrimary,
      ),
      h1: GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.48,
        color: textPrimary,
      ),
      h2: GoogleFonts.inter(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.18,
        color: textPrimary,
      ),
      body: GoogleFonts.inter(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyEmphasized: GoogleFonts.inter(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      meta: GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      caption: GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.66,
        color: textSecondary,
      ),
    );
  }

  /// Type ramp injected into the Material [TextTheme] so widgets that
  /// rely on `Theme.of(context).textTheme.bodyLarge` (etc.) pick up the
  /// 2027 metrics without any code changes.
  ///
  /// | Role            | Family    | Size | Line | Weight | Tracking |
  /// | Display Serif   | Newsreader| 36   | 44   | 500    | -0.02 em |
  /// | H1              | Inter     | 24   | 32   | 700    | -0.02 em |
  /// | H2              | Inter     | 18   | 26   | 600    | -0.01 em |
  /// | Body            | Inter     | 15   | 22   | 400    | 0        |
  /// | Body emphasized | Inter     | 15   | 22   | 500    | 0        |
  /// | Meta            | Inter     | 13   | 18   | 400    | 0        |
  /// | Caption         | Inter     | 11   | 16   | 600    | 0.06 em  |
  static TextTheme _buildTextTheme(
    Color textPrimary,
    Color textSecondary,
    Color textHint,
  ) {
    final h1 = GoogleFonts.inter(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.48,
      color: textPrimary,
    );
    final h2 = GoogleFonts.inter(
      fontSize: 18,
      height: 26 / 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.18,
      color: textPrimary,
    );
    final body = GoogleFonts.inter(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    );
    final bodyEm = GoogleFonts.inter(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    );
    final meta = GoogleFonts.inter(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    );
    final caption = GoogleFonts.inter(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.66,
      color: textHint,
    );

    return TextTheme(
      displayLarge: h1,
      displayMedium: h1,
      displaySmall: h2,
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h2,
      titleLarge: h2,
      titleMedium: bodyEm,
      titleSmall: bodyEm.copyWith(color: textSecondary),
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: meta,
      labelLarge: bodyEm,
      labelMedium: meta,
      labelSmall: caption,
    );
  }
}

/// Listd surface roles. Five 2027 surfaces (`ambient` / `canvas` /
/// `panel` / `card` / `chip`) plus the legacy `sidebar` / `detailPanel`
/// kept for back-compat with existing 2026 widgets. `shadowSm/Md/Lg`
/// carry the warm-tinted shadow tokens.
class ListdSurfaces extends ThemeExtension<ListdSurfaces> {
  const ListdSurfaces({
    required this.ambient,
    required this.canvas,
    required this.panel,
    required this.card,
    required this.chip,
    required this.sidebar,
    required this.detailPanel,
    required this.surfaceTint,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  final Color ambient;
  final Color canvas;
  final Color panel;
  final Color card;
  final Color chip;

  /// Legacy alias — equal to [panel] but kept so 2026 widgets keep
  /// compiling. Will be removed in P5 when the new sidebar drawer
  /// lands.
  final Color sidebar;

  /// Legacy alias — equal to [panel] but kept so 2026 widgets keep
  /// compiling. Will be removed in P3 when the inspector is dropped.
  final Color detailPanel;

  final Color surfaceTint;

  final BoxShadow shadowSm;
  final BoxShadow shadowMd;
  final BoxShadow shadowLg;

  @override
  ListdSurfaces copyWith({
    Color? ambient,
    Color? canvas,
    Color? panel,
    Color? card,
    Color? chip,
    Color? sidebar,
    Color? detailPanel,
    Color? surfaceTint,
    BoxShadow? shadowSm,
    BoxShadow? shadowMd,
    BoxShadow? shadowLg,
  }) {
    return ListdSurfaces(
      ambient: ambient ?? this.ambient,
      canvas: canvas ?? this.canvas,
      panel: panel ?? this.panel,
      card: card ?? this.card,
      chip: chip ?? this.chip,
      sidebar: sidebar ?? this.sidebar,
      detailPanel: detailPanel ?? this.detailPanel,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
    );
  }

  @override
  ListdSurfaces lerp(ThemeExtension<ListdSurfaces>? other, double t) {
    if (other is! ListdSurfaces) return this;
    return ListdSurfaces(
      ambient: Color.lerp(ambient, other.ambient, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      card: Color.lerp(card, other.card, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      detailPanel: Color.lerp(detailPanel, other.detailPanel, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      shadowSm: t < 0.5 ? shadowSm : other.shadowSm,
      shadowMd: t < 0.5 ? shadowMd : other.shadowMd,
      shadowLg: t < 0.5 ? shadowLg : other.shadowLg,
    );
  }
}

/// Listd 2027 motion tokens. One spring everywhere; carried on the
/// theme so widgets can access it without importing `spring.dart`
/// directly. The values mirror [ListdSpring].
class ListdMotion extends ThemeExtension<ListdMotion> {
  const ListdMotion({required this.duration, required this.curve});

  /// The single canonical motion token used across the app.
  static const ListdMotion standard = ListdMotion(
    duration: ListdSpring.duration,
    curve: ListdSpring.curve,
  );

  final Duration duration;
  final Curve curve;

  @override
  ListdMotion copyWith({Duration? duration, Curve? curve}) {
    return ListdMotion(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }

  @override
  ListdMotion lerp(ThemeExtension<ListdMotion>? other, double t) {
    if (other is! ListdMotion) return this;
    return ListdMotion(
      duration: t < 0.5 ? duration : other.duration,
      curve: t < 0.5 ? curve : other.curve,
    );
  }
}

/// Listd 2027 typography tokens. The Material `TextTheme` carries the
/// generic ramp; this extension carries the spec-named roles that have
/// no Material equivalent (notably `displaySerif`).
class ListdTypography extends ThemeExtension<ListdTypography> {
  const ListdTypography({
    required this.displaySerif,
    required this.h1,
    required this.h2,
    required this.body,
    required this.bodyEmphasized,
    required this.meta,
    required this.caption,
  });

  final TextStyle displaySerif;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle body;
  final TextStyle bodyEmphasized;
  final TextStyle meta;
  final TextStyle caption;

  @override
  ListdTypography copyWith({
    TextStyle? displaySerif,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? body,
    TextStyle? bodyEmphasized,
    TextStyle? meta,
    TextStyle? caption,
  }) {
    return ListdTypography(
      displaySerif: displaySerif ?? this.displaySerif,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      body: body ?? this.body,
      bodyEmphasized: bodyEmphasized ?? this.bodyEmphasized,
      meta: meta ?? this.meta,
      caption: caption ?? this.caption,
    );
  }

  @override
  ListdTypography lerp(ThemeExtension<ListdTypography>? other, double t) {
    if (other is! ListdTypography) return this;
    return ListdTypography(
      displaySerif: TextStyle.lerp(displaySerif, other.displaySerif, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyEmphasized: TextStyle.lerp(bodyEmphasized, other.bodyEmphasized, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}
