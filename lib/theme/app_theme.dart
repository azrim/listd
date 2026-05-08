import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Listd 2026 theme.
///
/// One typeface (Inter), one accent, two surfaces, hairline borders.
/// All metrics derive from the 4 px base grid:
///   - control radius: 8 px
///   - card radius:    12 px
///   - control height: 32 px (button, input, sync pill)
///   - row height:     44 px (task tile)
///   - sidebar item:   36 px
class AppTheme {
  AppTheme._();

  static const double controlRadius = 8;
  static const double cardRadius = 12;
  static const double controlHeight = 32;

  static ThemeData get darkTheme => _buildTheme(AppColors.darkScheme);
  static ThemeData get lightTheme => _buildTheme(AppColors.lightScheme);

  static ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: _buildTextTheme(
        scheme.onSurface,
        scheme.onSurfaceVariant,
        scheme.outline,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.22,
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
          side: BorderSide(color: scheme.outlineVariant),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

      // Buttons — 32 px tall, 12 px horizontal padding, 8 px radius,
      // body-emphasized text. One primary surface per screen.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.22,
          color: scheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          height: 22 / 15,
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
        circularTrackColor: scheme.surfaceContainer,
        linearMinHeight: 2,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      // No coloured splash/highlight — selection is instant + flat.
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
        ListdSurfaces(
          // Rail and inspector sit on the elevated surface so the list
          // pane (the page) reads as the bright surface.
          sidebar: scheme.surfaceContainerLow,
          detailPanel: scheme.surfaceContainerLow,
          surfaceTint: scheme.primary,
        ),
      ],
    );
  }

  /// Type ramp from the design spec.
  ///
  /// | Role            | Size | Line | Weight | Tracking |
  /// | Display H1      | 32   | 40   | 600    | -0.02 em |
  /// | Title H2        | 22   | 28   | 600    | -0.01 em |
  /// | Body            | 15   | 22   | 400    | 0        |
  /// | Body emphasized | 15   | 22   | 500    | 0        |
  /// | Meta            | 13   | 18   | 400    | 0        |
  /// | Caption         | 11   | 16   | 600    | 0.06 em  |
  static TextTheme _buildTextTheme(
    Color textPrimary,
    Color textSecondary,
    Color textHint,
  ) {
    TextStyle inter({
      required double size,
      required double line,
      required FontWeight weight,
      double tracking = 0,
      Color? color,
    }) => GoogleFonts.inter(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      letterSpacing: tracking * size,
      color: color ?? textPrimary,
    );

    final h1 = inter(
      size: 32,
      line: 40,
      weight: FontWeight.w600,
      tracking: -0.02,
    );
    final h2 = inter(
      size: 22,
      line: 28,
      weight: FontWeight.w600,
      tracking: -0.01,
    );
    final body = inter(size: 15, line: 22, weight: FontWeight.w400);
    final bodyEm = inter(size: 15, line: 22, weight: FontWeight.w500);
    final meta = inter(
      size: 13,
      line: 18,
      weight: FontWeight.w400,
      color: textSecondary,
    );
    final caption = inter(
      size: 11,
      line: 16,
      weight: FontWeight.w600,
      tracking: 0.06,
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

/// Listd-specific surface roles that don't have a direct Material 3
/// equivalent (sidebar tint, inspector tint).
class ListdSurfaces extends ThemeExtension<ListdSurfaces> {
  const ListdSurfaces({
    required this.sidebar,
    required this.detailPanel,
    required this.surfaceTint,
  });

  final Color sidebar;
  final Color detailPanel;
  final Color surfaceTint;

  @override
  ListdSurfaces copyWith({
    Color? sidebar,
    Color? detailPanel,
    Color? surfaceTint,
  }) {
    return ListdSurfaces(
      sidebar: sidebar ?? this.sidebar,
      detailPanel: detailPanel ?? this.detailPanel,
      surfaceTint: surfaceTint ?? this.surfaceTint,
    );
  }

  @override
  ListdSurfaces lerp(ThemeExtension<ListdSurfaces>? other, double t) {
    if (other is! ListdSurfaces) return this;
    return ListdSurfaces(
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      detailPanel: Color.lerp(detailPanel, other.detailPanel, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
    );
  }
}
