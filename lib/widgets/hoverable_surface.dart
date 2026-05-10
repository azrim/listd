import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Listd 2027 · Indigo Edition: shared interactive surface that
/// cross-fades its hover and selection fills via [AppMotion.flick].
///
/// Replaces the per-widget `bool _hovered + setState` pattern that was
/// duplicated across the sidebar drawer, top bar, command palette,
/// task action rail, and list picker. Each of those copies snapped
/// the fill instantly, in violation of the state-visual contract in
/// `docs/redesign/2027-indigo/02_tokens.md` (Hover / Selected fills).
///
/// The fill animates over [AppMotion.flickDuration] with
/// [AppMotion.flickCurve]. Reduced motion collapses the duration to
/// `Duration.zero` via [AppMotion.flickFor], honoring
/// `04_motion.md` §3 ("Reduced motion is total"). Beziers on color
/// transitions are explicitly allowed by the same spec line that
/// reserves them for "color and opacity".
///
/// `flick` (160 ms) is intentionally chosen over `settle` (220 ms)
/// for hover/select. `04_motion.md` line 33 lists settle for
/// "hover/select", but on low-contrast light-mode chips (~1.05 :1)
/// a 220 ms ramp reads as a sluggish gradient and a fast cursor
/// sweep produces ghosty overlap across rows. `flick` ("Tap feedback,
/// checkbox toggle — should feel like an immediate physical response")
/// is a much better fit for hover than the deliberate state-change
/// pace of `settle`, and stays inside the spec's three-calibration
/// budget rather than inventing a fourth.
///
/// The widget intentionally keeps a single visual responsibility
/// (animated fill). It does **not** add the hover `border-strong`
/// hairline mandated by `02_tokens.md` — that is a deliberate
/// follow-up audited separately so this refactor stays purely a
/// motion fix.
///
/// ### Don't return `Colors.transparent` from [fillFor].
///
/// `Colors.transparent` is `Color(0x00000000)` — alpha **and** RGB
/// are zero. When [AnimatedContainer.color] lerps from that toward
/// any non-transparent active fill, every intermediate frame
/// interpolates RGB toward `(0, 0, 0)` as well as alpha. At
/// t = 0.5 the rendered color is the active RGB ÷ 2 at alpha 128,
/// which composites onto a light parent surface as a **dark grey
/// flash** — the classic "Color.lerp through black" artefact.
/// On low-contrast light-mode chips (~1.05 :1) the dark dip is
/// visually louder than the chip itself, so the user perceives
/// hover as "dark briefly appears, then disappears, then accent
/// arrives" instead of a single smooth cross-fade.
///
/// Always return the would-be active color at alpha 0 instead.
/// e.g.:
///
/// ```dart
/// fillFor: (_, {required hovered, required selected}) => hovered
///     ? scheme.surfaceContainerHighest
///     : scheme.surfaceContainerHighest.withValues(alpha: 0),
/// ```
///
/// With the same RGB at both ends, the lerp is alpha-only and every
/// mid-frame composites to `lerp(parent, active, alpha)` — never
/// darker than the parent.
class HoverableSurface extends StatefulWidget {
  const HoverableSurface({
    super.key,
    required this.fillFor,
    this.child,
    this.builder,
    this.onTap,
    this.onSecondaryTapUp,
    this.onHover,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.border,
    this.cursor = SystemMouseCursors.click,
    this.selected = false,
  }) : assert(
         child != null || builder != null,
         'HoverableSurface needs either a child or a builder.',
       ),
       assert(
         child == null || builder == null,
         "HoverableSurface can't take both a child and a builder.",
       );

  /// Resolves the fill color for the current `(hovered, selected)`
  /// tuple. Callers map the tuple to spec colors (chip / accent-soft
  /// / transparent / etc.) per `02_tokens.md` Focus + state visuals.
  final Color Function(
    BuildContext context, {
    required bool hovered,
    required bool selected,
  })
  fillFor;

  /// Static contents. Use this when only the fill needs to react to
  /// `(hovered, selected)`. For sites that also need to vary text or
  /// icon colour with hover state (e.g. the `+ New list` affordance),
  /// pass [builder] instead.
  final Widget? child;

  /// Dynamic contents that re-build with the current state tuple.
  /// Useful when foreground colours animate alongside the fill — wrap
  /// the parts that depend on `hovered` / `selected` in
  /// `AnimatedDefaultTextStyle` / `TweenAnimationBuilder<Color>` so
  /// they ride the same calibration.
  final Widget Function(
    BuildContext context, {
    required bool hovered,
    required bool selected,
  })?
  builder;

  final VoidCallback? onTap;

  /// Right-click handler.
  ///
  /// Switched from `onSecondaryTapDown` to `onSecondaryTapUp` so the
  /// gesture arena resolves before any handler fires. With `TapDown`
  /// every recognizer the pointer hit-tested true on (parent
  /// `GestureDetector` + this `InkWell`) co-fires on the same event,
  /// which double-mounts context menus when the parent uses
  /// `HitTestBehavior.translucent` (e.g. the empty-area menu in
  /// `task_list_panel.dart`). `TapUp` waits for the arena, so the
  /// inner `InkWell` wins for clicks on a row and the outer parent
  /// wins for clicks on empty space.
  final ValueChanged<TapUpDetails>? onSecondaryTapUp;

  /// Optional callback fired on `MouseRegion.onEnter`. The command
  /// palette uses it to keep its keyboard cursor in sync with the
  /// pointer's row without taking ownership of the hover state.
  final VoidCallback? onHover;

  final BorderRadius borderRadius;

  /// Optional always-on border (e.g. the Search·⌘K pill's hairline).
  /// Hover/select transitions only animate the fill; the border stays
  /// constant so this widget doesn't introduce motion the spec
  /// doesn't require.
  final BoxBorder? border;

  final MouseCursor cursor;

  /// Whether the row is currently selected (route-active sidebar item,
  /// keyboard-cursor command palette row, …). The fill cross-fades
  /// when this flips, on the same calibration as hover.
  final bool selected;

  @override
  State<HoverableSurface> createState() => _HoverableSurfaceState();
}

class _HoverableSurfaceState extends State<HoverableSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fill = widget.fillFor(
      context,
      hovered: _hovered,
      selected: widget.selected,
    );
    final resolvedChild =
        widget.child ??
        widget.builder!(context, hovered: _hovered, selected: widget.selected);
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
        widget.onHover?.call();
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        // Hover/select fills run on `flick` (160 ms) — `settle`
        // (220 ms) was the literal read of `04_motion.md` line 33
        // ("settle | hover/select"), but on low-contrast light-mode
        // chips (`#F1F5F9` on `#F8FAFC`, ~1.05 :1) a 220 ms ramp
        // reads as a sluggish gradient instead of a hover affordance,
        // and a fast cursor sweep across the rail produces ghosty
        // overlap. `flick` is the next-faster spec-canonical
        // calibration ("Tap feedback, checkbox toggle — should feel
        // like an immediate physical response"), which is a much
        // better fit for hover than the deliberate state-change pace
        // of `settle`.
        duration: AppMotion.flickFor(context),
        curve: AppMotion.flickCurve,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: widget.borderRadius,
          border: widget.border,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          child: InkWell(
            onTap: widget.onTap,
            onSecondaryTapUp: widget.onSecondaryTapUp,
            borderRadius: widget.borderRadius,
            // We drive the visible hover fill from the
            // `AnimatedContainer` above. The `InkWell` would
            // otherwise paint its own (instant, ~4 % alpha) hover
            // overlay on top, which would compete with the cross-
            // fade and read as a double-hover.
            hoverColor: Colors.transparent,
            child: resolvedChild,
          ),
        ),
      ),
    );
  }
}
