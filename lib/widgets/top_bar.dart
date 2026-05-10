import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/overlays_provider.dart';
import '../providers/shell_state_provider.dart';
import '../providers/task_lists_provider.dart';
import 'context_menu.dart';
import 'hoverable_surface.dart';

/// Listd 2027 · Indigo Edition top bar.
///
/// 44 px tall, lives **inside** the canvas card (not above the whole
/// shell) per `03_list_view_light.png`. Renders:
///
///  * Left: panel toggle (collapses sidebar) + current page title.
///  * Right: `Search · ⌘K` pill + 28 px avatar.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = ref.watch(authNotifierProvider);
    final email = auth is AuthAuthenticated ? auth.session.user.email : null;
    final title = _pageTitle(context, ref);

    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _PanelToggle(
            onTap: () =>
                ref.read(sidebarDrawerOpenProvider.notifier).update((v) => !v),
          ),
          const SizedBox(width: 12),
          // `Expanded` (not `Flexible + Spacer`) so the title soaks up
          // *all* leftover space, parking the search pill + avatar
          // flush against the canvas card's right edge.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
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

  String _pageTitle(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/list/')) {
      final id = loc.substring('/list/'.length);
      final lists =
          ref.watch(taskListsNotifierProvider).valueOrNull ?? const [];
      for (final l in lists) {
        if (l.id == id) return l.title;
      }
      return 'List';
    }
    if (loc.startsWith('/today')) return 'Today';
    if (loc.startsWith('/inbox')) return 'Inbox';
    if (loc.startsWith('/important')) return 'Important';
    if (loc.startsWith('/planned')) return 'Planned';
    if (loc.startsWith('/all')) return 'All Tasks';
    if (loc.startsWith('/folders')) return 'Manage lists';
    if (loc.startsWith('/settings')) return 'Settings';
    return 'Listd';
  }
}

class _PanelToggle extends StatelessWidget {
  const _PanelToggle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Toggle sidebar · Ctrl + \\',
      child: HoverableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        fillFor: (_, {required hovered, required selected}) => hovered
            ? scheme.surfaceContainerHighest
            // Alpha-0 of the hover RGB keeps the cross-fade an
            // alpha-only lerp. Returning Colors.transparent here
            // would lerp through RGB (0, 0, 0) and flash a dark
            // grey square on the canvas (~#B8B9BB on white) for
            // ~80 ms on the way to the chip fill.
            : scheme.surfaceContainerHighest.withValues(alpha: 0),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Icon(
              PhosphorIcons.sidebarSimple(),
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.outline;

    return Tooltip(
      message: 'Search · Ctrl + K',
      child: HoverableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        fillFor: (_, {required hovered, required selected}) =>
            hovered ? scheme.surfaceContainerHighest : Colors.transparent,
        child: SizedBox(
          height: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.magnifyingGlass(), size: 14, color: fg),
                const SizedBox(width: 8),
                Text(
                  'Search · Ctrl+K',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
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
      message: widget.email ?? 'Account',
      child: GestureDetector(
        key: _avatarKey,
        onTap: () => _showAvatarMenu(context),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarMenu(BuildContext context) {
    final renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height + 6),
    );
    showListdContextMenu(context, position, [
      ListdContextMenuItem(
        icon: PhosphorIcons.gear(),
        label: 'Settings',
        onTap: () =>
            ref.read(settingsOverlayOpenProvider.notifier).state = true,
      ),
      ListdContextMenuItem(
        icon: PhosphorIcons.signOut(),
        label: 'Sign out',
        destructive: true,
        onTap: () async {
          await ref.read(authNotifierProvider.notifier).logout();
        },
      ),
    ]);
  }
}
