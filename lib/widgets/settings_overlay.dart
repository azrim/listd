import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_density.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Listd 2027 · Indigo Edition settings drawer.
///
/// Replaces the old centered modal — the indigo system rejects any
/// blurred backdrop primitive entirely. Per
/// `docs/redesign/2027-indigo/03_components.md` §6 the drawer:
///
///  * Slides in from the right edge using
///    `AppMotion.breatheDuration` (~320 ms, snaps to zero under
///    `MediaQuery.disableAnimations`).
///  * Is **opaque** — no blur, no transparency. The canvas behind
///    dims to a flat 40 % slate-900 scrim only.
///  * Is 560 px wide (or full canvas width on narrow viewports).
///  * Closes on Esc, on click-on-scrim, or on the X button.
///  * Persists every change immediately — there is no Save button.
///
/// Layout is two-pane internally (160 px rail + body) so the
/// information architecture is identical to the previous modal —
/// only the chrome changes.
class SettingsOverlay extends ConsumerStatefulWidget {
  const SettingsOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends ConsumerState<SettingsOverlay>
    with SingleTickerProviderStateMixin {
  static const double _drawerWidth = 560;

  _Category _selected = _Category.appearance;
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.breatheDuration,
    );
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.breatheCurve),
    );
    // Drive the controller forward on the next frame so reduced-motion
    // paths still resolve to a fully-open drawer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reducedMotion = MediaQuery.disableAnimationsOf(context);
      if (reducedMotion) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.panel ?? scheme.surface;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final width = mediaWidth < _drawerWidth ? mediaWidth : _drawerWidth;

    return Stack(
      children: [
        // Opaque scrim — slate-900 at 40 % opacity. No blur, no
        // gradient — the indigo system rejects glassmorphism entirely.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: FadeTransition(
              opacity: _controller,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: width,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: cardBg,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(
                    left: BorderSide(color: scheme.outline, width: 1),
                  ),
                  boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
                ),
                child: Row(
                  children: [
                    _Rail(
                      selected: _selected,
                      onChanged: (c) => setState(() => _selected = c),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: scheme.outline,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _Header(
                            title: _selected.label,
                            onClose: widget.onClose,
                          ),
                          Container(height: 1, color: scheme.outline),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                24,
                                32,
                                32,
                              ),
                              child: _CategoryBody(category: _selected),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Category { appearance, account, notifications, about }

extension on _Category {
  String get label {
    switch (this) {
      case _Category.appearance:
        return 'Appearance';
      case _Category.account:
        return 'Account';
      case _Category.notifications:
        return 'Notifications';
      case _Category.about:
        return 'About';
    }
  }

  IconData get icon {
    switch (this) {
      case _Category.appearance:
        return PhosphorIcons.paintBrush();
      case _Category.account:
        return PhosphorIcons.userCircle();
      case _Category.notifications:
        return PhosphorIcons.bell();
      case _Category.about:
        return PhosphorIcons.info();
    }
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.selected, required this.onChanged});

  final _Category selected;
  final ValueChanged<_Category> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 168,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            for (final c in _Category.values)
              _RailItem(
                category: c,
                selected: c == selected,
                onTap: () => onChanged(c),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.20,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close (Esc)',
            icon: Icon(PhosphorIcons.x(), size: 16),
            color: scheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _CategoryBody extends ConsumerWidget {
  const _CategoryBody({required this.category});

  final _Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (category) {
      case _Category.appearance:
        return const _AppearanceBody();
      case _Category.account:
        return const _AccountBody();
      case _Category.notifications:
        return const _NotificationsBody();
      case _Category.about:
        return const _AboutBody();
    }
  }
}

class _AppearanceBody extends ConsumerWidget {
  const _AppearanceBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scale = ref.watch(fontScaleProvider);
    final density = ref.watch(densityModeProvider);
    final accent = ref.watch(accentColorProvider);
    final driftEnabled = ref.watch(backplateDriftProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Theme'),
        const SizedBox(height: 8),
        // Per `05_settings_drawer_light.png` — sun / moon Phosphor
        // icons on the icon segments and plain "System". The whole
        // strip is a slate-soft tray; the selected segment is a white
        // / slate-card chip with no Material check overlay.
        _Segmented<ThemeMode>(
          value: mode,
          onChanged: (v) =>
              ref.read(themeModeProvider.notifier).setThemeMode(v),
          options: [
            _SegmentOption(
              value: ThemeMode.light,
              label: 'Light',
              icon: PhosphorIcons.sun(),
            ),
            _SegmentOption(
              value: ThemeMode.dark,
              label: 'Dark',
              icon: PhosphorIcons.moon(),
            ),
            const _SegmentOption(value: ThemeMode.system, label: 'System'),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel('Density'),
        const SizedBox(height: 8),
        _Segmented<DensityMode>(
          value: density,
          onChanged: (v) => ref.read(densityModeProvider.notifier).setMode(v),
          options: const [
            _SegmentOption(value: DensityMode.cozy, label: 'Cozy'),
            _SegmentOption(value: DensityMode.compact, label: 'Compact'),
          ],
        ),
        const SizedBox(height: 6),
        _HelperText('Cozy uses 56-pixel task rows; compact drops to 44.'),
        const SizedBox(height: 24),
        _SectionLabel('Text size'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: scale,
                min: FontScaleNotifier.minScale,
                max: FontScaleNotifier.maxScale,
                divisions: 12,
                label: '${(scale * 100).round()}%',
                onChanged: (v) =>
                    ref.read(fontScaleProvider.notifier).setScale(v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                '${(scale * 100).round()}%',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel('Accent'),
        const SizedBox(height: 8),
        _AccentSwatchPicker(
          selected: accent,
          onPick: (c) => ref.read(accentColorProvider.notifier).setAccent(c),
        ),
        const SizedBox(height: 8),
        _HelperText(
          'Indigo is the system default — alternates apply only to '
          'selection and primary buttons; functional dots remain '
          'emerald, amber, and red.',
        ),
        const SizedBox(height: 24),
        _SectionLabel('Backplate'),
        const SizedBox(height: 8),
        _DriftToggleRow(
          enabled: driftEnabled,
          onChanged: (v) =>
              ref.read(backplateDriftProvider.notifier).setEnabled(v),
        ),
        const SizedBox(height: 6),
        _HelperText(
          'Soft corner washes warm in the morning, cool in the evening. '
          'Disable to keep a static gradient.',
        ),
      ],
    );
  }
}

/// Indigo segmented control — replaces Material's `SegmentedButton`
/// (which paints an amber Material check icon over selected segments
/// in the current ColorScheme). Per `05_settings_drawer_light.png`
/// the strip is a slate-soft tray and the selected segment is a flat
/// white / slate-card chip with optional Phosphor icon.
class _SegmentOption<T> {
  const _SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<_SegmentOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opt in options)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _SegmentChip<T>(
                  selected: opt.value == value,
                  label: opt.label,
                  icon: opt.icon,
                  onTap: () => onChanged(opt.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip<T> extends StatelessWidget {
  const _SegmentChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final bool selected;
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5-swatch accent picker per `05_settings_drawer_light.png`. Each
/// swatch is a 24 px circle; the selected swatch gets an indigo ring.
class _AccentSwatchPicker extends StatelessWidget {
  const _AccentSwatchPicker({required this.selected, required this.onPick});

  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final swatch in kAccentSwatches)
          GestureDetector(
            onTap: () => onPick(swatch),
            // ignore: deprecated_member_use
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: swatch,
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: swatch.value == selected.value
                      ? scheme.onSurface
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Backplate drift toggle row — indigo checkbox + label per
/// `05_settings_drawer_light.png` (no Material switch).
class _DriftToggleRow extends StatelessWidget {
  const _DriftToggleRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(!enabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // 18-px indigo checkbox — slate hairline when off, indigo
            // fill + white check when on. Matches the Component
            // overview (10) checkbox treatment.
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: enabled ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: enabled ? scheme.primary : scheme.outline,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: enabled
                  ? Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 12,
                      color: scheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              'Time-of-day drift',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Italic helper text used under Accent + Backplate. Newsreader italic
/// reads slightly more like an inline note than Inter would.
class _HelperText extends StatelessWidget {
  const _HelperText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: GoogleFonts.newsreader(
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _AccountBody extends ConsumerWidget {
  const _AccountBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authNotifierProvider);
    final email = auth is AuthAuthenticated
        ? auth.session.user.email ?? '—'
        : 'Not signed in';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Signed in as'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.envelope(),
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
          onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Coming soon'),
        const SizedBox(height: 8),
        Text(
          'Push and email notification settings will land in the next release. '
          'For now Listd respects the platform notifications you opted into '
          'when granting permissions.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 20 / 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“The list is the page; the page is the work.”',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            height: 30 / 22,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.22,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel('Listd'),
        const SizedBox(height: 8),
        Text(
          'A local-first task manager. Capture in under a second, sync in '
          'the background, and stay focused on the list.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 20 / 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel('Design system'),
        const SizedBox(height: 8),
        Text(
          '2027 · Indigo Edition. Indigo + slate + amber on OKLCH. '
          'Inter and Newsreader. Phosphor icons. Single spring, three '
          'calibrations: settle, flick, breathe.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 20 / 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
