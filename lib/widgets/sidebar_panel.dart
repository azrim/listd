import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_lists_provider.dart';
import '../models/task_list.dart';

/// Provider for the currently selected task list ID
final selectedTaskListIdProvider = StateProvider<String?>((ref) => null);

/// Special list IDs for built-in views
class SpecialListIds {
  static const String myDay = '@myday';
  static const String important = '@important';
  static const String planned = '@planned';
  static const String tasks = '@tasks';
}

/// Left sidebar panel with task lists
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader(title: 'MY DAY'),
                _SidebarItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'My Day',
                  iconColor: Colors.orange,
                  isSelected: selectedListId == SpecialListIds.myDay,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.myDay,
                ),
                _SidebarItem(
                  icon: Icons.star_outline,
                  title: 'Important',
                  iconColor: colorScheme.primary,
                  isSelected: selectedListId == SpecialListIds.important,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.important,
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Planned',
                  iconColor: colorScheme.tertiary,
                  isSelected: selectedListId == SpecialListIds.planned,
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          SpecialListIds.planned,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _SectionHeader(title: 'MY LISTS'),
                _SidebarItem(
                  icon: Icons.inbox,
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
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Failed to load lists'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () => _showNewListDialog(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New list'),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/listd_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, _, _) => Icon(
                Icons.check_circle,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Listd',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewListDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    if (result != null && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating "$result"... (API not implemented yet)'),
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    String? subtitle,
    Color? iconColor,
    bool isSelected = false,
    required this.onTap,
  }) : subtitle = subtitle,
       iconColor = iconColor,
       isSelected = isSelected;

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withAlpha(128)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withAlpha(128)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                taskList.isDefault ? Icons.star : Icons.list,
                size: 20,
                color: taskList.isDefault
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  taskList.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
