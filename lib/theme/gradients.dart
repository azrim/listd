import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Listd 2026 surface tokens, exposed as `LinearGradient`s for backward
/// compatibility with screens that use
/// `BoxDecoration(gradient: AppGradients.foo)`.
///
/// **There are no real gradients in the 2026 system.** Every value below
/// is a flat solid surface dressed up as a single-stop gradient so the
/// existing call sites keep compiling without churn (including
/// `const BoxDecoration(gradient: …)`). New code should use a plain
/// `color:` instead.
class AppGradients {
  AppGradients._();

  /// Brand "gradient" — flat accent.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accent],
  );

  /// Dark-mode brand "gradient".
  static const LinearGradient primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentDark, AppColors.accentDark],
  );

  /// Auth screen background — flat near-black surface.
  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgDeep, AppColors.bgDeep],
  );

  /// Generic screen background — flat surface so legacy callers get
  /// the new neutral background instead of the old deep-blue gradient.
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgDeep, AppColors.bgDeep],
  );

  /// Selected sidebar item background. The 2026 system uses a 1-color
  /// fill (`accentSoft`) plus a left bar, so this resolves to
  /// `accentSoft`.
  static const LinearGradient navActiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentSoft, AppColors.accentSoft],
  );

  /// Light auth/screen background.
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgLight, AppColors.bgLight],
  );

  /// Subtle elevated surface. Resolves to the elevated neutral surface
  /// (`#FAFAFA` / `#121217`).
  static const LinearGradient surfaceGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgLightContainerLow, AppColors.bgLightContainerLow],
  );

  /// Card surface — flat neutral.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgContainer, AppColors.bgContainer],
  );

  /// Success surface (state pill).
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.success, AppColors.success],
  );

  /// Error surface (state pill).
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.error, AppColors.error],
  );

  /// Modal scrim — kept as a true two-stop gradient since this is a
  /// functional darkening overlay, not a brand gradient.
  static const LinearGradient overlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x80000000)],
  );
}
