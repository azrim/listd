import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/task_lists_provider.dart';
import '../theme/app_colors.dart';
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

/// Left sidebar panel with task lists - glassmorphism style
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withAlpha(179), // 70% opacity
            border: const Border(
              right: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: Colors.white10),
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
                      iconColor: AppColors.primary,
                      isSelected: selectedListId == SpecialListIds.important,
                      onTap: () =>
                          ref.read(selectedTaskListIdProvider.notifier).state =
                              SpecialListIds.important,
                    ),
                    _SidebarItem(
                      icon: Icons.calendar_today_outlined,
                      title: 'Planned',
                      iconColor: Colors.cyan,
                      isSelected: selectedListId == SpecialListIds.planned,
                      onTap: () =>
                          ref.read(selectedTaskListIdProvider.notifier).state =
                              SpecialListIds.planned,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.white10),
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
                                        .read(
                                          selectedTaskListIdProvider.notifier,
                                        )
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
                        child: Text(
                          'Failed to load lists',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // New list button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: _GlassButton(
                  icon: Icons.add,
                  label: 'New list',
                  onPressed: () => _showNewListDialog(context, ref),
                ),
              ),
              // Settings button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: _GlassButton(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/listd_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.check_circle, size: 32, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Listd',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
      // Create the list via provider
      ref.read(taskListsNotifierProvider.notifier).createTaskList(result);
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
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
    return Material(
      color: isSelected
          ? AppColors.primary.withAlpha(51) // 20% opacity
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
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
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
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
    return Material(
      color: isSelected
          ? AppColors.primary.withAlpha(51) // 20% opacity
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
                    ? AppColors.primary
                    : AppColors.textSecondary,
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
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

/// Glass-style button for sidebar actions
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
