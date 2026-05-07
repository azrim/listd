import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Application theme configuration using Material 3 with glassmorphism UI
class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(
    Color textPrimary,
    Color textSecondary,
    Color textHint,
  ) {
    final base = GoogleFonts.spaceGroteskTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: textPrimary),
      displayMedium: base.displayMedium?.copyWith(color: textPrimary),
      displaySmall: base.displaySmall?.copyWith(color: textPrimary),
      headlineLarge: base.headlineLarge?.copyWith(color: textPrimary),
      headlineMedium: base.headlineMedium?.copyWith(color: textPrimary),
      headlineSmall: base.headlineSmall?.copyWith(color: textPrimary),
      titleLarge: base.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(color: textSecondary),
      bodyLarge: base.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: base.bodyMedium?.copyWith(color: textSecondary),
      bodySmall: base.bodySmall?.copyWith(color: textSecondary),
      labelLarge: base.labelLarge?.copyWith(color: textPrimary),
      labelMedium: base.labelMedium?.copyWith(color: textSecondary),
      labelSmall: base.labelSmall?.copyWith(color: textHint),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
    required Color primary,
  }) {
    final textTheme = _buildTextTheme(textPrimary, textSecondary, textHint);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: brightness,
            surface: surfaceColor,
          ).copyWith(
            primary: primary,
            onPrimary: Colors.white,
            surface: surfaceColor,
            onSurface: textPrimary,
          ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withAlpha(179), // 70% opacity
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withAlpha(64), // 25% white border
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(15), // 6% white
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(31)), // 12%
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(31)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.spaceGrotesk(color: textHint),
        labelStyle: GoogleFonts.spaceGrotesk(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: IconThemeData(color: textSecondary),
      dividerTheme: DividerThemeData(color: Colors.white.withAlpha(31)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: GoogleFonts.spaceGrotesk(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.spaceGrotesk(color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: AppColors.bgDeep,
      surfaceColor: AppColors.bgSurface,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textHint: AppColors.textHint,
      primary: AppColors.primary,
    );
  }

  /// Dark theme configuration (default for glassmorphism)
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      backgroundColor: AppColors.bgDeep,
      surfaceColor: AppColors.bgSurface,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textHint: AppColors.textHint,
      primary: AppColors.primary,
    );
  }
}
