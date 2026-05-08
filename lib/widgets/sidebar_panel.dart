import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_colors.dart';

/// Sidebar panel with task lists - glassmorphism style
/// Re-exports provider for backward compatibility
export '../providers/ui_state_providers.dart'
    show selectedTaskListIdProvider, SpecialListIds;

/// Left sidebar panel with task lists
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
            color: AppColors.bgContainer.withAlpha(179),
            border: const Border(
              right: BorderSide(color: AppColors.glassBorderSubtle, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const Divider(height: 1, color: Colors.white10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _SectionHeader(title: 'MY DAY'),
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
                  onPressed: () {
                    // Navigate to settings - will be handled by router
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.secondary],
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Listd',
            style: GoogleFonts.manrope(
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
        backgroundColor: AppColors.bgContainerHigh,
        title: Text(
          'New list',
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'List name',
            hintStyle: GoogleFonts.manrope(color: AppColors.textHint),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Create', style: GoogleFonts.manrope()),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.manrope(
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
    this.isSelected = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.secondaryContainer.withAlpha(51)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
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

class _TaskListItem extends StatelessWidget {
  const _TaskListItem({
    required this.taskList,
    this.isSelected = false,
    required this.onTap,
  });

  final TaskList taskList;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.secondaryContainer.withAlpha(77)
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
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  taskList.title,
                  style: GoogleFonts.manrope(
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

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.glassBorderSubtle),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.manrope(
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
