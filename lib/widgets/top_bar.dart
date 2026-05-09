import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/overlays_provider.dart';
import 'context_menu.dart';

/// Listd 2027 · Indigo Edition top bar.
///
/// 40 px tall, sits above every screen that renders inside `AppShell`.
///
/// Per mockup `01_today_light.png`:
///
///  * No drawer toggle (the sidebar lives flush against the left edge
///    full-time on desktop; collapse via Ctrl + \).
///  * No page-title duplication — each page renders its own headline.
///  * Right cluster: `Search · ⌘K` pill + 28 px avatar.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = ref.watch(authNotifierProvider);
    final email = auth is AuthAuthenticated ? auth.session.user.email : null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const Spacer(),
          _SearchPill(
            onTap: () =>
                ref.read(commandPaletteOpenProvider.notifier).state = true,
          ),
          const SizedBox(width: 12),
          _Avatar(email: email),
        ],
      ),
    );
  }
}

class _SearchPill extends StatefulWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurfaceVariant;
    final fill = _hovered
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerLow;

    return Tooltip(
      message: 'Search · Ctrl + K',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.magnifyingGlass(), size: 14, color: fg),
                const SizedBox(width: 8),
                Text(
                  'Search',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 16 / 13,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 8),
                _KeybindChip(keys: const ['Ctrl', 'K']),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small inline keybind chip — used by the search pill, the capture
/// row, and (eventually) command palette suggestions. Mirrors the
/// hairline + tabular-figures treatment in mockup `01_today_light.png`.
class _KeybindChip extends StatelessWidget {
  const _KeybindChip({required this.keys});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        keys.join('+'),
        style: GoogleFonts.inter(
          fontSize: 10,
          height: 14 / 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.04,
        ),
      ),
    );
  }
}

class _Avatar extends ConsumerStatefulWidget {
  const _Avatar({this.email});

  final String? email;

  @override
  ConsumerState<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends ConsumerState<_Avatar> {
  final GlobalKey _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = (widget.email == null || widget.email!.isEmpty)
        ? '?'
        : widget.email!.substring(0, 1).toUpperCase();

    return Tooltip(
      message: widget.email ?? 'Not signed in',
      child: GestureDetector(
        onTap: _openMenuAtAnchor,
        onSecondaryTapDown: (details) => _openMenu(details.globalPosition),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            key: _avatarKey,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Anchor primary-click menu just below the avatar (its bottom-left
  /// corner). Right-click already lands at the cursor so we route that
  /// through `_openMenu` directly.
  void _openMenuAtAnchor() {
    final box = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset(0, box.size.height + 4));
    _openMenu(origin);
  }

  void _openMenu(Offset globalPosition) {
    showListdContextMenu(context, globalPosition, [
      ListdContextMenuItem(
        icon: PhosphorIcons.gear(),
        label: 'Settings',
        shortcut: 'Ctrl+,',
        onTap: () =>
            ref.read(settingsOverlayOpenProvider.notifier).state = true,
      ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: PhosphorIcons.signOut(),
        label: 'Sign out',
        destructive: true,
        onTap: () => ref.read(authNotifierProvider.notifier).logout(),
      ),
    ]);
  }
}
