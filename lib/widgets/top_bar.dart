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

/// Listd 2027 · Indigo Edition top bar.
///
/// 40 px tall, sits above every screen that renders inside `AppShell`.
///
/// Per `docs/redesign/2027-indigo/03_components.md` §2:
///
///  * Drawer toggle (8 px from the left edge).
///  * Active page title (Inter 18 px, weight 600).
///  * Spacer.
///  * Avatar (initials chip — 28 × 28).
///
/// The legacy "Listd" workspace pill and the duplicate `SyncStatusPill`
/// have been removed — the title carries the page identity, and the
/// sync pill lives **once** in the sidebar drawer footer.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOpen = ref.watch(sidebarDrawerOpenProvider);
    final auth = ref.watch(authNotifierProvider);
    final email = auth is AuthAuthenticated ? auth.session.user.email : null;
    final title = _pageTitle(context, ref);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: isOpen ? 'Close sidebar' : 'Open sidebar (Ctrl + \\)',
            icon: Icon(
              isOpen
                  ? PhosphorIcons.sidebar(PhosphorIconsStyle.fill)
                  : PhosphorIcons.sidebar(),
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            onPressed: () =>
                ref.read(sidebarDrawerOpenProvider.notifier).update((v) => !v),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.18,
                color: scheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          _Avatar(email: email),
        ],
      ),
    );
  }

  /// Derive the active page title from the matched go_router location.
  /// For `/list/:id`, look the list name up in `taskListsNotifierProvider`.
  String _pageTitle(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final loc = state.matchedLocation;
    switch (loc) {
      case '/today':
        return 'Today';
      case '/inbox':
        return 'Inbox';
      case '/important':
        return 'Important';
      case '/planned':
        return 'Planned';
      case '/all':
        return 'All Tasks';
      case '/folders':
        return 'Folders';
      case '/settings':
        return 'Settings';
    }
    if (loc.startsWith('/list/')) {
      final id = state.pathParameters['id'] ?? '';
      final lists = ref.watch(taskListsNotifierProvider).valueOrNull;
      if (lists != null) {
        for (final l in lists) {
          if (l.id == id) return l.title;
        }
      }
      return 'List';
    }
    return 'Listd';
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
