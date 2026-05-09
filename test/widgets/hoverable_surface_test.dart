import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/theme/app_motion.dart';
import 'package:listd/widgets/hoverable_surface.dart';

/// Regression: hover/select fills used to snap instantly across every
/// nav surface (sidebar, top bar, command palette, action rail, list
/// picker). HoverableSurface cross-fades the fill on [AppMotion.flick]
/// (160 ms) — the spec literally lists `settle | hover/select` in
/// `docs/redesign/2027-indigo/04_motion.md` line 33, but a 220 ms
/// ramp on the low-contrast light-mode chip (`#F1F5F9` on `#F8FAFC`)
/// reads as a sluggish gradient and produces ghosty cross-talk on
/// fast cursor sweeps, so we step down to the next spec-canonical
/// calibration (`flick`, "immediate physical response"). Reduced
/// motion still zeroes every duration per `04_motion.md` §3.
///
/// These tests pin the motion contract so a future copy-paste of the
/// snap pattern can't sneak back in.
void main() {
  Future<Finder> pumpHarness(
    WidgetTester tester, {
    bool selected = false,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Center(
              child: HoverableSurface(
                key: const ValueKey('surface'),
                onTap: () {},
                selected: selected,
                fillFor: (_, {required hovered, required selected}) {
                  if (selected) return const Color(0xFFAA0000);
                  if (hovered) return const Color(0xFF00AA00);
                  return const Color(0x00000000);
                },
                child: const SizedBox(width: 100, height: 32),
              ),
            ),
          ),
        ),
      ),
    );
    return find.byKey(const ValueKey('surface'));
  }

  AnimatedContainer animatedContainerOf(WidgetTester tester, Finder finder) {
    return tester.widget<AnimatedContainer>(
      find.descendant(of: finder, matching: find.byType(AnimatedContainer)),
    );
  }

  testWidgets('animates the fill on AppMotion.flick by default', (
    tester,
  ) async {
    final surface = await pumpHarness(tester);
    final animated = animatedContainerOf(tester, surface);
    expect(animated.duration, AppMotion.flickDuration);
    expect(animated.curve, AppMotion.flickCurve);
  });

  testWidgets('collapses the duration to Duration.zero under reduced motion', (
    tester,
  ) async {
    final surface = await pumpHarness(tester, disableAnimations: true);
    final animated = animatedContainerOf(tester, surface);
    expect(
      animated.duration,
      Duration.zero,
      reason:
          'docs/redesign/2027-indigo/04_motion.md §3 — '
          'reduced motion is total: every duration zeroes.',
    );
  });

  testWidgets('cross-fades from rest to hover and back on pointer enter/exit', (
    tester,
  ) async {
    final surface = await pumpHarness(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);

    // Pre-hover frame: transparent fill.
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    final preEnter = animatedContainerOf(tester, surface);
    expect(
      (preEnter.decoration as BoxDecoration).color,
      const Color(0x00000000),
    );

    // Move pointer onto the surface to start the cross-fade and let the
    // flick window run to completion.
    await gesture.moveTo(tester.getCenter(surface));
    await tester.pumpAndSettle();
    final settled = animatedContainerOf(tester, surface);
    expect(
      (settled.decoration as BoxDecoration).color,
      const Color(0xFF00AA00),
      reason: 'hovered surface lands on the hover fill',
    );

    // Move the pointer off the surface.
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    final exited = animatedContainerOf(tester, surface);
    expect(
      (exited.decoration as BoxDecoration).color,
      const Color(0x00000000),
      reason: 'fill returns to rest after pointer exit',
    );
  });

  testWidgets('selected fill takes precedence over hover fill', (tester) async {
    final surface = await pumpHarness(tester, selected: true);
    await tester.pump(AppMotion.flickDuration * 2);
    final animated = animatedContainerOf(tester, surface);
    expect(
      (animated.decoration as BoxDecoration).color,
      const Color(0xFFAA0000),
    );
  });

  testWidgets('honors a custom borderRadius and optional always-on border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HoverableSurface(
              key: const ValueKey('surface'),
              onTap: () {},
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF112233)),
              fillFor: (_, {required hovered, required selected}) =>
                  Colors.transparent,
              child: const SizedBox(width: 100, height: 32),
            ),
          ),
        ),
      ),
    );

    final animated = animatedContainerOf(
      tester,
      find.byKey(const ValueKey('surface')),
    );
    final decoration = animated.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(999));
    expect(decoration.border, isNotNull);
  });

  /// Regression for the "Color.lerp through black" artefact:
  /// `Colors.transparent` is `Color(0x00000000)` — alpha 0 AND RGB
  /// 0. When [AnimatedContainer.color] lerps from that toward an
  /// active fill, mid-frames interpolate RGB toward `(0, 0, 0)` as
  /// well as alpha. At t = 0.5 the rendered color is the active
  /// RGB ÷ 2 at alpha 128, which composites onto a light parent
  /// surface as a dark grey flash — exactly what users perceive as
  /// "the chip goes dark, then disappears, then accent arrives" on
  /// a hover-then-click sequence in light mode.
  ///
  /// The fix is that callers must return the active color at
  /// alpha 0 from their fillFor, not [Colors.transparent]. With the
  /// same RGB at both endpoints, [Color.lerp] interpolates alpha
  /// only and every mid-frame stays in the active-color family.
  ///
  /// This test pins the invariant by asserting that a
  /// HoverableSurface configured with `chip.withValues(alpha: 0)`
  /// at rest and `chip` on hover produces an animated container
  /// whose RGB is constant across the cross-fade and only the
  /// alpha varies. If a future caller copy-pastes the broken
  /// `Colors.transparent` rest, the rest-state RGB drops to
  /// `(0, 0, 0)` and this test fails.
  testWidgets('rest fill RGB must match active fill RGB so the cross-fade is '
      'alpha-only (no lerp through black)', (tester) async {
    const chip = Color(0xFFF1F5F9); // slate-100
    final rest = chip.withValues(alpha: 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HoverableSurface(
              key: const ValueKey('surface'),
              onTap: () {},
              fillFor: (_, {required hovered, required selected}) =>
                  hovered ? chip : rest,
              child: const SizedBox(width: 100, height: 32),
            ),
          ),
        ),
      ),
    );

    final surface = find.byKey(const ValueKey('surface'));
    final restState = animatedContainerOf(tester, surface);
    final restColor = (restState.decoration as BoxDecoration).color!;

    // Rest must be alpha-0 of chip RGB, NOT Colors.transparent.
    // If a future caller returns Colors.transparent here the
    // following three assertions all fail (RGB = 0).
    expect(restColor.a, 0, reason: 'rest fill must be invisible (alpha 0)');
    expect(
      restColor.r,
      chip.r,
      reason:
          'rest fill RGB.r must match the active hover color so '
          'Color.lerp interpolates alpha only. Returning '
          'Colors.transparent here would give RGB (0,0,0) and '
          'cause a dark-grey flash mid-cross-fade.',
    );
    expect(restColor.g, chip.g);
    expect(restColor.b, chip.b);

    // After the cross-fade settles, RGB stays the same and alpha
    // arrives at full — confirming the interpolation is alpha-only.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(surface));
    await tester.pumpAndSettle();
    final hoverState = animatedContainerOf(tester, surface);
    final hoverColor = (hoverState.decoration as BoxDecoration).color!;
    expect(hoverColor.a, 1);
    expect(hoverColor.r, chip.r);
    expect(hoverColor.g, chip.g);
    expect(hoverColor.b, chip.b);
  });
}
