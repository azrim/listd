import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Listd 2027 · Indigo Edition: shared interactive surface that
/// cross-fades its hover and selection fills via [AppMotion.settle].
///
/// Replaces the per-widget `bool _hovered + setState` pattern that was
/// duplicated across the sidebar drawer, top bar, command palette,
/// task action rail, and list picker. Each of those copies snapped
/// the fill instantly, in violation of the canonical motion rule
/// "settle · Default state changes — task expand/collapse, sidebar
/// selection move, color theme swap"
/// (`docs/redesign/2027-indigo/04_motion.md` §When to use which) and
/// the state-visual table in `02_tokens.md` (Hover / Selected fills).
///
/// The fill animates over [AppMotion.settleDuration] with
/// [AppMotion.settleCurve]. Reduced motion collapses the duration to
/// `Duration.zero` via [AppMotion.settleFor], honoring
/// `04_motion.md` §3 ("Reduced motion is total"). Beziers on color
/// transitions are explicitly allowed by the same spec line that
/// reserves them for "color and opacity".
///
/// The widget intentionally keeps a single visual responsibility
/// (animated fill). It does **not** add the hover `border-strong`
/// hairline mandated by `02_tokens.md` — that is a deliberate
/// follow-up audited separately so this refactor stays purely a
/// motion fix.
class HoverableSurface extends StatefulWidget {
  const HoverableSurface({
    super.key,
    required this.fillFor,
    this.child,
    this.builder,
    this.onTap,
    this.onSecondaryTapDown,
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
  final ValueChanged<TapDownDetails>? onSecondaryTapDown;

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
        duration: AppMotion.settleFor(context),
        curve: AppMotion.settleCurve,
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
            onSecondaryTapDown: widget.onSecondaryTapDown,
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
