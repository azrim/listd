import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/theme/app_colors.dart';
import 'package:listd/theme/app_theme.dart';

/// Pins the surface-stack invariants per `mockups/png/02_today_dark.png`:
///
///  * Sidebar `panel` and right-hand `canvas` are the same surface in
///    dark mode — separation is carried by hairlines, not a
///    brightness step.
///  * `outlineVariant` (the 1 px hairline) is a different RGB from
///    `panel` AND from `canvas` in both modes, so the panel edges,
///    sync-pill borders, and dialog seams remain visible.
///  * `surfaces.card` is one stop brighter than `panel` in dark so
///    the expanded task card / sync pill have real separation.
///
/// Theme construction lives inside the test bodies so GoogleFonts
/// isn't called at group-discovery time (some font lookups need the
/// Flutter binding which is only initialized once `testWidgets`
/// pumps a tester).
void main() {
  ListdSurfaces surfaces(ThemeData theme) => theme.extension<ListdSurfaces>()!;

  group('Dark surface stack', () {
    testWidgets('panel == canvas (per the 02_today_dark mock)', (tester) async {
      final s = surfaces(AppTheme.darkTheme);
      expect(s.panel, s.canvas);
      expect(s.panel, AppColors.slate900);
    });

    testWidgets('outlineVariant has visible contrast against panel/canvas', (
      tester,
    ) async {
      final theme = AppTheme.darkTheme;
      final s = surfaces(theme);
      final outline = theme.colorScheme.outlineVariant;
      expect(outline, isNot(s.panel));
      expect(outline, isNot(s.canvas));
      // slate-700 against slate-900 is a 2-stop jump — visible 1 px
      // hairline against the dark panel.
      expect(outline, AppColors.slate700);
    });

    testWidgets('card is reserved for hover overlays / pill lift surface', (
      tester,
    ) async {
      final s = surfaces(AppTheme.darkTheme);
      // card → slate-700, panel → slate-900. The expanded task card
      // is supposed to feel as bright as the canvas (same alpha-0
      // canvas RGB), so `card` is reserved for hover overlays + the
      // sync pill's lift surface, not for the card's own fill.
      expect(s.card, AppColors.slate700);
      expect(s.card, isNot(s.panel));
    });

    testWidgets('chip is one slate stop brighter than card', (tester) async {
      final s = surfaces(AppTheme.darkTheme);
      expect(s.chip, AppColors.slate600);
      expect(s.chip, isNot(s.card));
    });
  });

  group('Light surface stack', () {
    testWidgets('panel + canvas live in the same light family', (tester) async {
      // Light panel is `slate-50` and canvas is `#FFFFFF` — visually
      // they read as the same on the indigo backplate. We don't pin
      // the literal equality (they ARE different bytes), but we DO
      // pin that they're both within the "light surface" family.
      final s = surfaces(AppTheme.lightTheme);
      expect(s.panel, AppColors.slate50);
      expect(s.canvas, const Color(0xFFFFFFFF));
    });

    testWidgets('outlineVariant has visible contrast against panel/canvas', (
      tester,
    ) async {
      final theme = AppTheme.lightTheme;
      final s = surfaces(theme);
      final outline = theme.colorScheme.outlineVariant;
      expect(outline, isNot(s.panel));
      expect(outline, isNot(s.canvas));
      // slate-200 (bumped from slate-100) against slate-50 panel —
      // visible 1 px hairline.
      expect(outline, AppColors.slate200);
    });
  });
}
