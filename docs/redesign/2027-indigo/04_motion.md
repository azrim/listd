# 04 · Motion

## Single canonical spring, three calibrations

The 2027 system mandated one spring (`mass 1, k 280, c 28`). We
preserve that mathematical curve and add **named calibrations** so
callers don't pick numbers — they pick intent.

```dart
// lib/theme/app_motion.dart
class AppMotion {
  AppMotion._();

  static const spring = SpringDescription(mass: 1.0, stiffness: 280, damping: 28);

  static const settle  = SpringDescription(mass: 1.0, stiffness: 280, damping: 28); // ~220 ms — DEFAULT
  static const flick   = SpringDescription(mass: 1.0, stiffness: 380, damping: 30); // ~160 ms
  static const breathe = SpringDescription(mass: 1.0, stiffness: 180, damping: 24); // ~320 ms

  // Non-spring fallback (rare).
  static const tactileCurve = Cubic(0.32, 0.72, 0.0, 1.0);

  static Duration durationFor(BuildContext context, [Duration base = const Duration(milliseconds: 220)]) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : base;
  }
}
```

## When to use which

| Token | When | Examples |
| --- | --- | --- |
| `settle` | Default. Anything that is a state change, not an entry. | Task expand/collapse, sidebar selection move, color theme swap |
| `flick` | Tap-feedback motion under 200 ms. | Checkbox press, star toggle, button press shrink |
| `breathe` | Surfaces that *enter* a route or modal. The user expects them to take a beat. | Settings drawer slide-in, capture sheet drop-down, command palette fade-up, expanded card initial mount |

A single component should never use two springs. If you find yourself
wanting to, the component is doing two jobs.

## Choreography rules

### 1. Origin must be visible

Every entering element animates *from* a position the user can map to
something on screen.

| Element | Origin |
| --- | --- |
| Capture sheet | Top edge of canvas (drops down) |
| Settings drawer | Right edge (slides left) |
| Context menu | Pointer / cursor (scales from 0.94 to 1.0) |
| Command palette | Top-center (fades up + slight scale) |
| Newly created task | The capture row (slides down to its rank, soft indigo flash) |
| Expanded task card | Its own collapsed footprint (scales height only, no scale-x) |

Things that fade-only without origin: nothing. Even the sync-state dot
crossfades color via `Color.lerp` over 200 ms — it does not just blink.

### 2. Collapse waits

Closing motion holds for **40 ms** before unwinding so the gesture
doesn't feel nervous. Implementation: a `Future.delayed(Duration(ms: 40))`
between the user input and the spring start, gated by reduced motion.

### 3. Reduced motion is total

`MediaQuery.of(context).disableAnimations == true` triggers:

- All `AnimationController` durations = `Duration.zero`
- All slides become opacity-only crossfades
- All springs replaced with `Duration.zero` jumps
- The Today date track stops its idle "today pulse"
- The `AppBackplate` time-of-day drift stops (static stops only)

Test this in CI by mounting the widget tree with
`MediaQueryData(disableAnimations: true)` and asserting that no
`AnimationController` is alive after the first frame.

## Forbidden motion patterns

- **Looping idle animations.** Nothing breathes/pulses/rotates without
  user input. Exception: the 6-px sync-state dot may pulse during
  active sync.
- **Bounce.** Springs are critically/over-damped. No undershoot/overshoot
  beyond the natural settle of `c=28`.
- **Bezier curves on layout.** All layout transitions go through a
  spring. Beziers are reserved for color and opacity.
- **Stagger.** No "items animate in 50 ms apart" choreography. List
  rows mount instantly when their data lands; they don't sequence.
