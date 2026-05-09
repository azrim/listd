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
}
