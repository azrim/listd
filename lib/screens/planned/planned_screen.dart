import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task.dart';
import '../../providers/task_lists_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

/// Provider for all tasks across all lists (for planned view)
final allTasksProvider = FutureProvider<List<Task>>((ref) async {
  // Get all task lists first
  final taskListsAsync = ref.watch(taskListsStreamProvider);

  return taskListsAsync.when(
    data: (taskLists) async {
      final allTasks = <Task>[];
      for (final list in taskLists) {
        final tasksAsync = ref.watch(tasksStreamProvider(list.id));
        tasksAsync.whenData((tasks) {
          allTasks.addAll(tasks);
        });
      }
      return allTasks;
    },
    loading: () => <Task>[],
    error: (_, _) => <Task>[],
  );
});

/// Planned screen with date groupings.
class PlannedScreen extends ConsumerWidget {
  const PlannedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060818), Color(0xFF0D1535), Color(0xFF162040)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) => _buildContent(tasks),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.glassBorderSubtle)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'Planned',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeekEnd = today.add(const Duration(days: 7));

    // Filter and categorize tasks with due dates
    final tasksWithDue = allTasks
        .where((t) => t.due != null && !t.isCompleted)
        .toList();

    final overdue = tasksWithDue.where((t) => t.due!.isBefore(today)).toList();
    final todayTasks = tasksWithDue.where((t) {
      final dueDay = DateTime(t.due!.year, t.due!.month, t.due!.day);
      return dueDay == today;
    }).toList();
    final tomorrowTasks = tasksWithDue.where((t) {
      final dueDay = DateTime(t.due!.year, t.due!.month, t.due!.day);
      return dueDay == tomorrow;
    }).toList();
    final nextWeekTasks = tasksWithDue.where((t) {
      final dueDay = DateTime(t.due!.year, t.due!.month, t.due!.day);
      return dueDay.isAfter(tomorrow) && dueDay.isBefore(nextWeekEnd);
    }).toList();
    final laterTasks = tasksWithDue.where((t) {
      final dueDay = DateTime(t.due!.year, t.due!.month, t.due!.day);
      return dueDay.isAfter(nextWeekEnd) ||
          dueDay.isAtSameMomentAs(nextWeekEnd);
    }).toList();

    final hasAnyTasks =
        overdue.isNotEmpty ||
        todayTasks.isNotEmpty ||
        tomorrowTasks.isNotEmpty ||
        nextWeekTasks.isNotEmpty ||
        laterTasks.isNotEmpty;

    if (!hasAnyTasks) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overdue.isNotEmpty) ...[
            _DateSection(
              icon: Icons.warning,
              iconColor: AppColors.danger,
              title: 'Overdue',
              tasks: overdue,
            ),
            const SizedBox(height: 24),
          ],
          if (todayTasks.isNotEmpty) ...[
            _DateSection(
              icon: Icons.calendar_today,
              iconColor: AppColors.primary,
              title: 'Today',
              tasks: todayTasks,
            ),
            const SizedBox(height: 24),
          ],
          if (tomorrowTasks.isNotEmpty) ...[
            _DateSection(
              icon: Icons.calendar_today,
              iconColor: AppColors.textPrimary,
              title: 'Tomorrow',
              tasks: tomorrowTasks,
            ),
            const SizedBox(height: 24),
          ],
          if (nextWeekTasks.isNotEmpty) ...[
            _DateSection(
              icon: Icons.calendar_today,
              iconColor: AppColors.textPrimary,
              title: 'Next 7 Days',
              tasks: nextWeekTasks,
              isGrid: true,
            ),
            const SizedBox(height: 24),
          ],
          if (laterTasks.isNotEmpty) ...[
            _DateSection(
              icon: Icons.schedule,
              iconColor: AppColors.textHint,
              title: 'Later',
              tasks: laterTasks,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No planned tasks',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks with due dates will appear here',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Date section with header and tasks
class _DateSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Task> tasks;
  final bool isGrid;

  const _DateSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.tasks,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon,
            iconColor: iconColor,
            title: title,
            taskCount: tasks.length,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: icon,
          iconColor: iconColor,
          title: title,
          taskCount: tasks.length,
        ),
        const SizedBox(height: 12),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskCard(task: task),
          ),
        ),
      ],
    );
  }
}

/// Section header with icon and title
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int taskCount;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.glassBorderSubtle),
        ),
        const SizedBox(width: 8),
        Text(
          '$taskCount',
          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}

/// Task card for planned view
class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              // Toggle completion
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Task title
          Expanded(
            child: Text(
              task.title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Due date
          if (task.due != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatDueDate(task.due!),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = dateDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${-diff}d ago';
    return '${date.day}/${date.month}';
  }
}
