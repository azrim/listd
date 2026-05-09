import 'package:flutter/material.dart';

/// Listd 2027 — single spring used for every animation.
///
/// One curve, identical mass / stiffness / damping across the app, so motion
/// feels uniformly deliberate. Settles in ~220 ms; reverse uses the same
/// physics with a 40 ms delay so close motions feel intentional, not nervous.
///
/// See `listd_2027_design_spec.md` §5.1.
class ListdSpring {
  ListdSpring._();

  /// Standard spring physics. Mass 1.0, stiffness 280, damping 28.
  static const SpringDescription standard = SpringDescription(
    mass: 1.0,
    stiffness: 280,
    damping: 28,
  );

  /// Target settle duration when the spring is approximated by a tween
  /// (e.g. inside an `AnimationController`).
  static const Duration duration = Duration(milliseconds: 220);

  /// Reverse animations wait this long before unwinding so collapse motions
  /// don't read as nervous.
  static const Duration reverseDelay = Duration(milliseconds: 40);

  /// Returns either the standard spring duration or `Duration.zero` when the
  /// platform is in reduced-motion mode.
  ///
  /// Reduced motion is signalled by `MediaQueryData.disableAnimations`.
  /// Callers should also bypass curves and gradient drift in that mode —
  /// see the design spec §5 / §6.
  static Duration durationFor(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : duration;
  }

  /// Convenience curve that approximates the standard spring for callers that
  /// can't use a `SpringSimulation` directly (e.g. `AnimatedContainer`).
  ///
  /// Tuned to feel close to the spring at the same total duration.
  static const Curve curve = Cubic(0.2, 0.8, 0.2, 1);
}
