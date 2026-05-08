import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_colors.dart';

export '../providers/ui_state_providers.dart'
    show selectedTaskListIdProvider, SpecialListIds;

class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border: Border(right: BorderSide(color: Color(0xFF1A2040), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Container(height: 1, color: const Color(0xFF1A2040)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _SectionHeader(title: 'MY DAY'),
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
                Container(height: 1, color: const Color(0xFF1A2040)),
                const SizedBox(height: 8),
                const _SectionHeader(title: 'MY LISTS'),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Failed to load lists',
                      style: TextStyle(color: Color(0xFF8C8A97)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF1A2040)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _GlassButton(
              icon: Icons.add,
              label: 'New list',
              onPressed: () => _showNewListDialog(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _GlassButton(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Listd',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
        backgroundColor: const Color(0xFF1A2040),
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
              style: GoogleFonts.manrope(color: const Color(0xFF8C8A97)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8C8A97).withValues(alpha: 0.5),
          letterSpacing: 1.5,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border(left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF8C8A97).withValues(alpha: 0.7),
                ),
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
                          ? Colors.white
                          : const Color(0xFF8C8A97).withValues(alpha: 0.7),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border(left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  taskList.isDefault ? Icons.star : Icons.list,
                  size: 20,
                  color: taskList.isDefault
                      ? Colors.amber
                      : const Color(0xFF8C8A97).withValues(alpha: 0.7),
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
                          ? Colors.white
                          : const Color(0xFF8C8A97).withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2040),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A3A), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: const Color(0xFF8C8A97)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF8C8A97),
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
