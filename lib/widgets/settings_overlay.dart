import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Listd 2027 P7 settings overlay.
///
/// 560 × 640 px modal mounted from `AppShell`. The **only** allowed
/// blurred backdrop in the codebase — the P7 grep gate asserts that
/// the blur primitive appears in exactly one place, and this is it.
///
/// Two-pane layout:
///
///  * Left rail (160 px) — category picker (Appearance / Account /
///    Notifications).
///  * Right pane — settings for the active category. Uses simple
///    list rows that share the same hairline + 8 px radius
///    primitive as the rest of the 2027 system.
class SettingsOverlay extends ConsumerStatefulWidget {
  const SettingsOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends ConsumerState<SettingsOverlay> {
  _Category _selected = _Category.appearance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.panel ?? scheme.surface;

    return Stack(
      children: [
        // The single allowed blurred backdrop in the codebase —
        // frosts the canvas behind the modal so the eye locks onto
        // the dialog.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
        ),
        Center(
          child: Material(
            color: cardBg,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 560,
              height: 640,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant, width: 1),
                boxShadow: [
                  surfaces?.shadowMd ?? const BoxShadow(),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    _Rail(
                      selected: _selected,
                      onChanged: (c) => setState(() => _selected = c),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _Header(
                            title: _selected.label,
                            onClose: widget.onClose,
                          ),
                          Container(height: 1, color: scheme.outlineVariant),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                24,
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

enum _Category { appearance, account, notifications }

extension on _Category {
  String get label {
    switch (this) {
      case _Category.appearance:
        return 'Appearance';
      case _Category.account:
        return 'Account';
      case _Category.notifications:
        return 'Notifications';
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
      width: 160,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w600,
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
    }
  }
}

class _AppearanceBody extends ConsumerWidget {
  const _AppearanceBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scale = ref.watch(fontScaleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Theme'),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ],
          selected: {mode},
          onSelectionChanged: (s) =>
              ref.read(themeModeProvider.notifier).setThemeMode(s.first),
        ),
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
      ],
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
          onPressed: () =>
              ref.read(authNotifierProvider.notifier).logout(),
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
