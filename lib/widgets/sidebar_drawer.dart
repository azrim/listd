import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task_list.dart';
import '../providers/shell_state_provider.dart';
import '../providers/task_lists_provider.dart';
import '../providers/today_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'context_menu.dart';
import 'rename_dialog.dart';
import 'sync_status_pill.dart';

/// Listd 2027 · Indigo Edition sidebar drawer.
///
/// Hidden by default; rendered on top of the app via a `Stack` inside
/// `AppShell`. Shown when `sidebarDrawerOpenProvider` is `true`.
///
/// Per `docs/redesign/2027-indigo/03_components.md` §3 the drawer
/// drops three things from the previous warm version:
///
///  * Workspace / account block at the top — gone.
///  * Bottom `[Settings] [Sign out]` button row — gone.
///  * Duplicate `SyncStatusPill` — single instance, full-width footer.
///
/// 240 px wide, flush against the left edge with a 1 px hairline
/// border on the right.
class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  static const double width = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final taskListsAsync = ref.watch(taskListsNotifierProvider);
    final currentLocation = GoRouterState.of(context).uri.toString();

    final inboxCount = ref.watch(inboxTasksProvider).valueOrNull?.length ?? 0;
    final todayCount = ref.watch(todayTasksProvider).valueOrNull?.length ?? 0;
    final importantCount =
        ref.watch(importantTasksProvider).valueOrNull?.length ?? 0;
    final plannedCount =
        ref.watch(plannedTasksProvider).valueOrNull?.length ?? 0;

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
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _SectionHeader(label: 'SMART'),
                  _DrawerItem(
                    icon: PhosphorIcons.sun(),
                    label: 'Today',
                    count: todayCount > 0 ? todayCount : null,
                    isSelected: currentLocation == '/today',
                    onTap: () => _navigate(context, ref, '/today'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.tray(),
                    label: 'Inbox',
                    count: inboxCount > 0 ? inboxCount : null,
                    isSelected: currentLocation == '/inbox',
                    onTap: () => _navigate(context, ref, '/inbox'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                    iconTint: AppColors.amber400,
                    label: 'Important',
                    count: importantCount > 0 ? importantCount : null,
                    isSelected: currentLocation == '/important',
                    onTap: () => _navigate(context, ref, '/important'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.calendar(),
                    label: 'Planned',
                    count: plannedCount > 0 ? plannedCount : null,
                    isSelected: currentLocation == '/planned',
                    onTap: () => _navigate(context, ref, '/planned'),
                  ),
                  _DrawerItem(
                    icon: PhosphorIcons.listChecks(),
                    label: 'All Tasks',
                    isSelected: currentLocation == '/all',
                    onTap: () => _navigate(context, ref, '/all'),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(label: 'LISTS'),
                  taskListsAsync.when(
                    data: (lists) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final l in lists)
                          _DrawerItem(
                            icon: PhosphorIcons.bookmark(),
                            label: l.title,
                            isSelected: currentLocation == '/list/${l.id}',
                            onTap: () =>
                                _navigate(context, ref, '/list/${l.id}'),
                            onSecondaryTapDown: (details) =>
                                _showListContextMenu(
                                  context,
                                  ref,
                                  details.globalPosition,
                                  l,
                                ),
                          ),
                        _NewListItem(onTap: () => _createList(context, ref)),
                      ],
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
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: SyncStatusPill(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, WidgetRef ref, String path) {
    context.go(path);
    ref.read(sidebarDrawerOpenProvider.notifier).state = false;
  }

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final name = await showRenameDialog(
      context,
      title: 'New list',
      initial: '',
      confirmLabel: 'Create',
      hintText: 'List name',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(taskListsNotifierProvider.notifier)
        .createTaskList(name.trim());
  }

  void _showListContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
    TaskList list,
  ) {
    showListdContextMenu(context, globalPosition, [
      ListdContextMenuItem(
        icon: PhosphorIcons.pencilSimple(),
        label: 'Rename',
        onTap: () async {
          final next = await showRenameDialog(
            context,
            title: 'Rename list',
            initial: list.title,
            confirmLabel: 'Rename',
            hintText: 'List name',
          );
          if (next == null || next == list.title) return;
          await ref
              .read(taskListsNotifierProvider.notifier)
              .updateTaskList(list.copyWith(title: next));
        },
      ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: PhosphorIcons.trash(),
        label: 'Delete list',
        destructive: true,
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final confirmed = await showDestructiveConfirm(
            context,
            title: 'Delete list?',
            message:
                'Delete "${list.title}" and all of its tasks? This can\'t be undone.',
            confirmLabel: 'Delete',
          );
          if (confirmed != true) return;
          await ref
              .read(taskListsNotifierProvider.notifier)
              .deleteTaskList(list.id);
          messenger.showSnackBar(
            SnackBar(content: Text('Deleted "${list.title}"')),
          );
        },
      ),
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 11,
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
    this.count,
    this.iconTint,
    this.onSecondaryTapDown,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Optional count badge rendered to the right of the label
  /// (e.g. `Inbox  3`). Hidden when null or 0.
  final int? count;

  /// Optional fixed tint for the leading icon — used by **Important**
  /// to render the star in amber regardless of selection state.
  final Color? iconTint;

  /// Right-click handler.
  final GestureTapDownCallback? onSecondaryTapDown;

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
    Color iconColor;
    if (widget.isSelected) {
      fill = scheme.primaryContainer;
      fg = scheme.primary;
      iconColor = widget.iconTint ?? scheme.primary;
    } else if (_hovered) {
      fill = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
      iconColor = widget.iconTint ?? scheme.onSurfaceVariant;
    } else {
      fill = Colors.transparent;
      fg = scheme.onSurface;
      iconColor = widget.iconTint ?? scheme.onSurfaceVariant;
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
            onSecondaryTapDown: widget.onSecondaryTapDown,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: iconColor),
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
                    if (widget.count != null && widget.count! > 0)
                      _CountBadge(
                        count: widget.count!,
                        selected: widget.isSelected,
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

/// Tiny tabular count chip rendered to the right of a sidebar row.
/// Selected state inherits the indigo soft, otherwise renders as a
/// neutral slate chip per `03_components.md` §3.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// "+ New list" affordance pinned to the bottom of the LISTS section.
class _NewListItem extends StatefulWidget {
  const _NewListItem({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NewListItem> createState() => _NewListItemState();
}

class _NewListItemState extends State<_NewListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = _hovered ? scheme.onSurface : scheme.onSurfaceVariant;
    final fill = _hovered ? scheme.surfaceContainerHighest : Colors.transparent;
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
                    Icon(PhosphorIcons.plus(), size: 16, color: fg),
                    const SizedBox(width: 12),
                    Text(
                      'New list',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w500,
                        color: fg,
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
