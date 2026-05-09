import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card surface — 16 px radius, soft warm shadow, no blur, no border.
///
/// In the 2027 system this is a bordered-or-shadowed warm surface that
/// auto-picks colors from `Theme.of(context).colorScheme` and the
/// `ListdSurfaces` extension, so existing call sites keep compiling and
/// pick up the new look without changes. The legacy "Glass" name is
/// retained as an alias only.
///
/// New code should use a plain `Container` + `ListdSurfaces.card` /
/// `shadowSm` instead.
// Deprecated — alias only.
// New code should use Container + ListdSurfaces.card / shadowSm.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.cardRadius,
    this.glowColor,
    this.width,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  /// Retained for API compatibility — ignored in the 2027 system.
  final Color? glowColor;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ListdSurfaces>();
    final shadow = surfaces?.shadowSm;
    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: surfaces?.card ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow == null ? null : <BoxShadow>[shadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

/// Same as [GlassCard], without the `InkWell`.
// Deprecated — alias only.
// New code should use Container + ListdSurfaces.card / shadowSm.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppTheme.cardRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ListdSurfaces>();
    final shadow = surfaces?.shadowSm;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaces?.card ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow == null ? null : <BoxShadow>[shadow],
      ),
      child: child,
    );
  }
}

/// Small chip / tag. Pill-shaped (999 px radius), warm muted fill, no
/// border. Auto-picks the 2027 chip token from `ListdSurfaces.chip`.
// Deprecated — alias only.
// New code should use Container + ListdSurfaces.chip + pillRadius.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = AppTheme.controlRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ListdSurfaces>();
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaces?.chip ?? theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
