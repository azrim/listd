import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Listd 2027 — the surface stack uses solid warm-neutral fills, not
/// gradients. The single allowed gradient lives behind the canvas
/// as the [AppBackplate]. New code uses a plain `color:` from
/// `Theme.of(context).colorScheme` or the [ListdSurfaces] extension.

/// Listd 2027 — ambient backplate.
///
/// Wraps the entire app and renders the soft, low-contrast radial
/// gradient that lives behind every surface. Two soft radial corners
/// (top-left + bottom-right) sit on the ambient base color. Their alpha
/// shifts subtly with the time of day — morning warmer (TL pulses),
/// evening cooler (BR pulses). This is the only place ambient color is
/// allowed to move. See `listd_2027_design_spec.md` §3.2.
///
/// Reduced-motion (`MediaQuery.disableAnimations`) freezes the drift to
/// the value at first build.
class AppBackplate extends StatefulWidget {
  const AppBackplate({
    super.key,
    required this.child,
    @visibleForTesting this.clock,
  });

  final Widget child;

  /// Test seam — when set, [clock] returns the current time instead of
  /// `DateTime.now()`. Production callers leave this null.
  final DateTime Function()? clock;

  @override
  State<AppBackplate> createState() => _AppBackplateState();
}

class _AppBackplateState extends State<AppBackplate> {
  static const Duration _tickInterval = Duration(minutes: 1);

  Timer? _timer;
  late DateTime _now;

  DateTime get _clockNow =>
      widget.clock != null ? widget.clock!() : DateTime.now();

  @override
  void initState() {
    super.initState();
    _now = _clockNow;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(_tickInterval, (_) {
        if (!mounted) return;
        setState(() => _now = _clockNow);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final stops = AppBackplateStops.forTime(brightness: brightness, at: _now);
    return ColoredBox(
      color: stops.base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.0, -1.0),
                radius: 1.4,
                colors: <Color>[stops.topLeft, stops.topLeftFade],
                stops: const <double>[0.0, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, 1.0),
                radius: 1.4,
                colors: <Color>[stops.bottomRight, stops.bottomRightFade],
                stops: const <double>[0.0, 1.0],
              ),
            ),
          ),
          // Child sits on top of both radials.
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// Resolved corner stops for the [AppBackplate] at a given brightness +
/// time of day. Pure data, easy to unit-test.
class AppBackplateStops {
  const AppBackplateStops({
    required this.base,
    required this.topLeft,
    required this.topLeftFade,
    required this.bottomRight,
    required this.bottomRightFade,
  });

  final Color base;
  final Color topLeft;
  final Color topLeftFade;
  final Color bottomRight;
  final Color bottomRightFade;

  /// Resolve stops for the given brightness + time. The TL/BR alpha
  /// pulses by ~5% across the day so morning reads warmer + evening
  /// cooler, but the drift is intentionally subtle (the spec says
  /// "feeling, not image").
  static AppBackplateStops forTime({
    required Brightness brightness,
    required DateTime at,
  }) {
    final dayFraction = (at.hour * 3600 + at.minute * 60 + at.second) / 86400.0;
    // Sine wave centered on noon — 0 at midnight, 1 at noon.
    final phase = (dayFraction - 0.25) * 2 * math.pi;
    final morning = (math.sin(phase) + 1) / 2;
    final evening = 1.0 - morning;

    if (brightness == Brightness.light) {
      return AppBackplateStops(
        base: AppColors.bgLight,
        topLeft: AppColors.ambientLightStartTopLeft.withValues(
          alpha: 0.50 + 0.10 * morning,
        ),
        topLeftFade: AppColors.ambientLightStartTopLeft.withValues(alpha: 0.0),
        bottomRight: AppColors.ambientLightStartBottomRight.withValues(
          alpha: 0.45 + 0.10 * evening,
        ),
        bottomRightFade: AppColors.ambientLightStartBottomRight.withValues(
          alpha: 0.0,
        ),
      );
    }
    return AppBackplateStops(
      base: AppColors.bgDeep,
      topLeft: AppColors.ambientDarkStartTopLeft.withValues(
        alpha: 0.65 + 0.15 * morning,
      ),
      topLeftFade: AppColors.ambientDarkStartTopLeft.withValues(alpha: 0.0),
      bottomRight: AppColors.ambientDarkStartBottomRight.withValues(
        alpha: 0.60 + 0.15 * evening,
      ),
      bottomRightFade: AppColors.ambientDarkStartBottomRight.withValues(
        alpha: 0.0,
      ),
    );
  }
}
