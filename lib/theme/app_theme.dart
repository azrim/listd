import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Application theme configuration using Material 3.
///
/// Based on the Stitch "Midnight Studio" design language.
/// Dark theme is the default with light theme as secondary.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────
  // DARK THEME (DEFAULT)
  // ─────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      // Background layers - lighter is higher
      bgDeep: AppColors.bgDeep,
      bgSurface: AppColors.bgContainer,
      bgContainer: AppColors.bgSurface,
      // Text colors
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textHint: AppColors.textHint,
      // Outlines
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      // Surface tint
      surfaceTint: AppColors.primaryLight,
      // Error
      error: AppColors.errorDark,
    );
  }

  // ─────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      // Background layers
      bgDeep: AppColors.bgLight,
      bgSurface: AppColors.bgLightContainerLow,
      bgContainer: AppColors.bgLightSurface,
      // Text colors
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textHint: AppColors.textHintLight,
      // Outlines
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      // Surface tint
      surfaceTint: AppColors.primary,
      // Error
      error: AppColors.error,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bgDeep,
    required Color bgSurface,
    required Color bgContainer,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
    required Color outline,
    required Color outlineVariant,
    required Color surfaceTint,
    required Color error,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color Scheme
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: isDark ? AppColors.primaryLight : AppColors.primary,
            brightness: brightness,
            surface: bgSurface,
            onSurface: textPrimary,
            error: error,
            surfaceContainerHighest: isDark
                ? AppColors.bgContainerHighest
                : AppColors.bgLightContainerHighest,
          ).copyWith(
            primary: isDark ? AppColors.primaryLight : AppColors.primary,
            onPrimary: isDark ? AppColors.primary : Colors.white,
            primaryContainer: AppColors.primaryContainer,
            onPrimaryContainer: AppColors.onPrimaryContainer,
            secondary: AppColors.secondary,
            onSecondary: Colors.white,
            secondaryContainer: AppColors.secondaryContainer,
            onSecondaryContainer: AppColors.onSecondaryContainer,
            surface: bgSurface,
            outline: outline,
            outlineVariant: outlineVariant,
            surfaceTint: surfaceTint,
          ),

      // Scaffold
      scaffoldBackgroundColor: bgDeep,

      // Text Theme
      textTheme: _buildTextTheme(textPrimary, textSecondary, textHint),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: isDark
            ? AppColors.bgContainer.withAlpha(179)
            : AppColors.bgLightContainerHighest.withAlpha(255),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(26)
                : AppColors.outlineVariant.withAlpha(128),
            width: 1,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withAlpha(38)
            : AppColors.bgLightContainerLow,
        hintStyle: GoogleFonts.manrope(color: textHint),
        labelStyle: GoogleFonts.manrope(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 2,
          ),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Icon
      iconTheme: IconThemeData(color: textSecondary),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withAlpha(26) : outlineVariant,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.bgContainerHighest : bgContainer,
        contentTextStyle: GoogleFonts.manrope(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.bgContainerHigh : bgContainer,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.manrope(color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.primaryLight : AppColors.primary,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.bgContainerHighest
            : AppColors.bgLightContainerHigh,
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static TextTheme _buildTextTheme(
    Color textPrimary,
    Color textSecondary,
    Color textHint,
  ) {
    return TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02,
        color: textHint,
      ),
    );
  }
}
