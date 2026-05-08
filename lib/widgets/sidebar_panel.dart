import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_theme.dart' show AppTheme, ListdSurfaces;
import 'app_logo.dart';
import 'sync_status_pill.dart';

export '../providers/ui_state_providers.dart'
    show selectedTaskListIdProvider, SpecialListIds;

/// Listd 2026 sidebar.
///
/// Lives on the elevated surface (`surfaceContainerLow`) so the list
/// pane reads as the bright surface. Items are 36 px tall with 18 px
/// icons and 15 px labels. Selected items get an `accent-soft` fill +
/// 2 px accent left bar — no rounded selection chip, no glow.
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final taskListsAsync = ref.watch(taskListsNotifierProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final divider = scheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: surfaces?.sidebar ?? scheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(scheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _SectionHeader(title: 'My day'),
                _SidebarItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'My Day',
                  isSelected: selectedListId == SpecialListIds.myDay,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.myDay,
                ),
                _SidebarItem(
                  icon: Icons.star_outline,
                  title: 'Important',
                  isSelected: selectedListId == SpecialListIds.important,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.important,
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Planned',
                  isSelected: selectedListId == SpecialListIds.planned,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.planned,
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Lists'),
                _SidebarItem(
                  icon: Icons.inbox_outlined,
                  title: 'Tasks',
                  isSelected: selectedListId == SpecialListIds.tasks,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.tasks,
                ),
                taskListsAsync.when(
                  data: (taskLists) => Column(
                    children: taskLists
                        .map(
                          (taskList) => _TaskListItem(
                            taskList: taskList,
                            isSelected: selectedListId == taskList.id,
                            onTap: () =>
                                ref
                                    .read(selectedTaskListIdProvider.notifier)
                                    .state = taskList
                                    .id,
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Failed to load lists',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: const SyncStatusPill(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _SidebarFooterButton(
              icon: Icons.add,
              label: 'New list',
              onPressed: () => _showNewListDialog(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _SidebarFooterButton(
              icon: Icons.folder_outlined,
              label: 'Folders',
              onPressed: () => context.push('/folders'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: _SidebarFooterButton(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          const AppLogo(size: 22),
          const SizedBox(width: 10),
          Text(
            'Listd',
            style: GoogleFonts.inter(
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              letterSpacing: -0.34,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewListDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New list'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'List name'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      ref.read(taskListsNotifierProvider.notifier).createTaskList(result);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.66,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SidebarRow(
      isSelected: isSelected,
      onTap: onTap,
      icon: icon,
      title: title,
    );
  }
}

class _TaskListItem extends StatelessWidget {
  const _TaskListItem({
    required this.taskList,
    required this.isSelected,
    required this.onTap,
  });
  final TaskList taskList;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SidebarRow(
      isSelected: isSelected,
      onTap: onTap,
      icon: taskList.isDefault ? Icons.star : Icons.list,
      title: taskList.title,
    );
  }
}

/// 36 px tall row with `accent-soft` fill + 2 px left bar when selected.
class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFg = scheme.onSurface;
    final unselectedFg = scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isSelected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: SizedBox(
            height: 36,
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected ? scheme.primary : unselectedFg,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 22 / 15,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: isSelected ? selectedFg : unselectedFg,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _SidebarFooterButton extends StatelessWidget {
  const _SidebarFooterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
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
