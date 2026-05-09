import 'package:flutter/widgets.dart';

import 'spring.dart';

/// Listd 2027 · Indigo Edition motion tokens.
///
/// One canonical spring with three named calibrations. A single
/// component should never use two — if it wants to, the component is
/// doing two jobs.
///
/// | Calibration | Mass | Stiffness | Damping | Settle  | Use                                |
/// | ----------- | ---: | --------: | ------: | ------: | ---------------------------------- |
/// | `settle`    |  1.0 |       280 |      28 | ~220 ms | Default state changes, hover/select |
/// | `flick`     |  1.0 |       380 |      30 | ~160 ms | Tap feedback, checkbox toggle       |
/// | `breathe`   |  1.0 |       180 |      24 | ~320 ms | Sheet / drawer enter, settings     |
///
/// `settle` is identical to the legacy `ListdSpring.standard`; new
/// callers should prefer `AppMotion.settle` so the calibration is
/// explicit at the call site.
///
/// Reduced motion (`MediaQuery.disableAnimations`) collapses every
/// duration to `Duration.zero`. Use [durationFor] or pair durations
/// with [Duration.zero] checks at call sites.
class AppMotion {
  AppMotion._();

  // ── Spring physics ─────────────────────────────────────────

  /// Default calibration. Used everywhere unless a faster or slower
  /// calibration is justified by the spec. Settles in ~220 ms.
  static const SpringDescription settle = SpringDescription(
    mass: 1.0,
    stiffness: 280,
    damping: 28,
  );

  /// Quick tap feedback. Used by checkboxes, star toggles, anywhere a
  /// click should feel like an immediate physical response. ~160 ms.
  static const SpringDescription flick = SpringDescription(
    mass: 1.0,
    stiffness: 380,
    damping: 30,
  );

  /// Slower, more generous motion. Used by sheets, drawers, settings
  /// reveal — anything that should feel like an inhale. ~320 ms.
  static const SpringDescription breathe = SpringDescription(
    mass: 1.0,
    stiffness: 180,
    damping: 24,
  );

  // ── Approximation curves + durations ───────────────────────
  //
  // For widgets that can't use a `SpringSimulation` directly
  // (`AnimatedContainer`, `AnimationController`, etc.) we approximate
  // each spring with a duration + curve. Keep these tuned to the
  // matching spring's settle time.

  /// Approximate duration for [settle]. Identical to
  /// `ListdSpring.duration` for back-compat.
  static const Duration settleDuration = Duration(milliseconds: 220);

  /// Approximate duration for [flick].
  static const Duration flickDuration = Duration(milliseconds: 160);

  /// Approximate duration for [breathe].
  static const Duration breatheDuration = Duration(milliseconds: 320);

  /// Curve for [settle]-paced animations. Smooth, low-overshoot.
  static const Curve settleCurve = Cubic(0.2, 0.8, 0.2, 1);

  /// Curve for [flick]-paced animations. Snappier ease-in-out.
  static const Curve flickCurve = Cubic(0.4, 0.0, 0.2, 1);

  /// Curve for [breathe]-paced animations. Generous decelerate.
  static const Curve breatheCurve = Cubic(0.0, 0.0, 0.2, 1);

  // ── Reverse delay ──────────────────────────────────────────

  /// Reverse animations wait this long before unwinding so collapse
  /// motions don't read as nervous. Same value as `ListdSpring.reverseDelay`.
  static const Duration reverseDelay = Duration(milliseconds: 40);

  // ── Reduced-motion helpers ─────────────────────────────────

  /// Returns either the supplied duration or `Duration.zero` when the
  /// platform is in reduced-motion mode.
  ///
  /// Pass any of [settleDuration], [flickDuration], or [breatheDuration]
  /// (or a custom value) — the helper just zeros it on reduced motion.
  static Duration durationFor(BuildContext context, Duration base) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : base;
  }

  /// Convenience: [durationFor] with [settleDuration] as the default.
  static Duration settleFor(BuildContext context) =>
      durationFor(context, settleDuration);

  /// Convenience: [durationFor] with [flickDuration] as the default.
  static Duration flickFor(BuildContext context) =>
      durationFor(context, flickDuration);

  /// Convenience: [durationFor] with [breatheDuration] as the default.
  static Duration breatheFor(BuildContext context) =>
      durationFor(context, breatheDuration);
}

// Smoke check — `AppMotion.settle` mirrors the legacy single-spring
// physics on `ListdSpring.standard` so existing widgets that still
// import `spring.dart` see the exact same motion they did before. If
// either side changes, this assertion fails at startup in debug mode.
@pragma('vm:prefer-inline')
bool debugAssertSpringParity() {
  assert(
    AppMotion.settle.mass == ListdSpring.standard.mass &&
        AppMotion.settle.stiffness == ListdSpring.standard.stiffness &&
        AppMotion.settle.damping == ListdSpring.standard.damping,
    'AppMotion.settle and ListdSpring.standard must agree on physics.',
  );
  return true;
}
