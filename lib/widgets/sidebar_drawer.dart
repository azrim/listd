import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/overlays_provider.dart';
import '../providers/shell_state_provider.dart';
import '../providers/task_lists_provider.dart';
import '../theme/app_theme.dart';
import 'sync_status_pill.dart';

/// Listd 2027 sidebar drawer.
///
/// Hidden by default; rendered on top of the app via a `Stack` inside
/// `AppShell`. Shown when `sidebarDrawerOpenProvider` is `true`.
///
/// Anatomy (top → bottom):
///
///  * Workspace identity / account block
///  * Smart lists (Today / Inbox / Important / Planned / All Tasks)
///  * User lists (from `taskListsNotifierProvider`)
///  * Footer (sync pill, settings, profile)
///
/// 280 px wide. Sits flush against the left edge with a 1 px hairline
/// border on the right and a subtle shadow.
class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  static const double width = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final auth = ref.watch(authNotifierProvider);
    final email = auth is AuthAuthenticated ? auth.session.user.email : null;
    final taskListsAsync = ref.watch(taskListsNotifierProvider);
    final currentLocation = GoRouterState.of(context).uri.toString();

    return MouseRegion(
      onEnter: (_) => ref.read(sidebarDrawerOpenProvider.notifier).state = true,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: surfaces?.panel ?? scheme.surfaceContainerLow,
          border: Border(right: BorderSide(color: scheme.outlineVariant)),
          boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(email: email),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _SectionHeader(label: 'SMART'),
                  _DrawerItem(
                    icon: PhosphorIcons.sun(),
                    label: 'Today',
                    isSelected: currentLocation == '/today',
                    onTap: () => _navigate(context, ref, '/today'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.tray(),
                    label: 'Inbox',
                    isSelected: currentLocation == '/inbox',
                    onTap: () => _navigate(context, ref, '/inbox'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.star(),
                    label: 'Important',
                    isSelected: currentLocation == '/important',
                    onTap: () => _navigate(context, ref, '/important'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.calendar(),
                    label: 'Planned',
                    isSelected: currentLocation == '/planned',
                    onTap: () => _navigate(context, ref, '/planned'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.listChecks(),
                    label: 'All Tasks',
                    isSelected: currentLocation == '/all',
                    onTap: () => _navigate(context, ref, '/all'),
                  ),
                  const SizedBox(height: 12),
                  _SectionHeader(label: 'LISTS'),
                  taskListsAsync.when(
                    data: (lists) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: lists
                          .map(
                            (l) => _DrawerItem(
                              icon: PhosphorIcons.bookmark(),
                              label: l.title,
                              isSelected: currentLocation == '/list/${l.id}',
                              onTap: () =>
                                  _navigate(context, ref, '/list/${l.id}'),
                            ),
                          )
                          .toList(),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Failed to load lists',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: const SyncStatusPill(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _FooterAction(
                      icon: PhosphorIcons.gear(),
                      label: 'Settings',
                      onTap: () {
                        ref
                            .read(sidebarDrawerOpenProvider.notifier)
                            .state = false;
                        ref
                            .read(settingsOverlayOpenProvider.notifier)
                            .state = true;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FooterAction(
                      icon: PhosphorIcons.signOut(),
                      label: 'Sign out',
                      onTap: () =>
                          ref.read(authNotifierProvider.notifier).logout(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, WidgetRef ref, String path) {
    context.go(path);
    // Auto-close the drawer once the user navigates so the canvas
    // takes back the full width.
    ref.read(sidebarDrawerOpenProvider.notifier).state = false;
  }
}

class _Header extends StatelessWidget {
  const _Header({this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
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
              (email == null || email!.isEmpty)
                  ? '?'
                  : email!.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listd',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (email != null)
                  Text(
                    email!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 16 / 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatefulWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color fill;
    Color fg;
    if (widget.isSelected) {
      fill = scheme.primaryContainer;
      fg = scheme.primary;
    } else if (_hovered) {
      fill = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
    } else {
      fill = Colors.transparent;
      fg = scheme.onSurface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 18 / 14,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: fg,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
