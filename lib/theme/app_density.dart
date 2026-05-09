import 'package:flutter/widgets.dart';

/// Two density modes for Listd 2027 · Indigo Edition.
///
/// **Cozy** is the default — generous metrics, ample breathing room.
/// **Compact** drops row, control, and canvas-padding metrics by ~30 %
/// for power users with thousands of tasks. Compact is desktop-only;
/// touch devices stay on Cozy because the compact targets fall below
/// the 44 px Android touch floor.
enum DensityMode {
  cozy,
  compact;

  /// Display-friendly label for settings UI.
  String get label => this == DensityMode.cozy ? 'Cozy' : 'Compact';

  /// String token for `shared_preferences` round-tripping.
  String get key => name;

  /// Inverse of [key]; returns [cozy] when the input is unknown.
  static DensityMode fromKey(String? key) {
    if (key == DensityMode.compact.name) return DensityMode.compact;
    return DensityMode.cozy;
  }
}

/// Per-mode metric helpers. Always read these instead of hardcoding
/// row / control / padding values in widget code.
class AppDensity {
  AppDensity._();

  /// Collapsed task row height. 56 (cozy) / 44 (compact).
  static double rowTask(DensityMode m) => m == DensityMode.cozy ? 56 : 44;

  /// Sidebar nav row height. 36 (cozy) / 32 (compact).
  static double rowNav(DensityMode m) => m == DensityMode.cozy ? 36 : 32;

  /// Step row height inside an expanded task. 32 (cozy) / 28 (compact).
  static double rowStep(DensityMode m) => m == DensityMode.cozy ? 32 : 28;

  /// Control height (button, input, sync pill). 36 (cozy) / 32 (compact).
  static double control(DensityMode m) => m == DensityMode.cozy ? 36 : 32;

  /// Vertical gap between adjacent task rows.
  static double gapList(DensityMode m) => m == DensityMode.cozy ? 12 : 8;

  /// Vertical gap between sections within a panel.
  static double gapSections(DensityMode m) => m == DensityMode.cozy ? 16 : 12;

  /// Outer padding for the canvas / list pane.
  static EdgeInsets canvasPadding(DensityMode m) => m == DensityMode.cozy
      ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
      : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
}
