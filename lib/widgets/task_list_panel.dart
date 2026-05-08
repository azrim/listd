import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_colors.dart';

/// Main task list panel - 3-column layout middle column
class TaskListPanel extends ConsumerWidget {
  final String listId;
  final String listName;
  final Function(Task)? onTaskSelected;

  const TaskListPanel({
    super.key,
    required this.listId,
    required this.listName,
    this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider(listId));
    final selectedTaskId = ref.watch(selectedTaskIdProvider);

    return Column(
      children: [
        // Header
        _buildHeader(context, ref),
        // Stats strip
        _StatsStrip(tasksAsync: tasksAsync),
        // Add task input at TOP
        _AddTaskInput(listId: listId),
        // Task list
        Expanded(
          child: tasksAsync.when(
            data: (tasks) => _buildContent(context, ref, tasks, selectedTaskId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref, e),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              listName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => ref
                .read(tasksNotifierProvider(listId).notifier)
                .syncFromRemote(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    String? selectedTaskId,
  ) {
    final mainTasks = tasks.where((t) => t.parentId == null).toList();

    if (mainTasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(tasksNotifierProvider(listId).notifier).syncFromRemote(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: mainTasks.length,
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _TaskRow(
              task: task,
              isSelected: selectedTaskId == task.id,
              onTap: () {
                ref.read(selectedTaskIdProvider.notifier).state = task.id;
                onTaskSelected?.call(task);
              },
              onToggle: () => ref
                  .read(tasksNotifierProvider(listId).notifier)
                  .toggleComplete(task),
              onDelete: () => _confirmDelete(context, ref, task),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text(
          'Delete task',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(tasksNotifierProvider(listId).notifier)
          .deleteTask(task.id);
    }
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          const Text(
            'Failed to load tasks',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref
                .read(tasksNotifierProvider(listId).notifier)
                .syncFromRemote(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Add a task above',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// Stats strip showing task counts - glass card row
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.tasksAsync});

  final AsyncValue<List<Task>> tasksAsync;

  @override
  Widget build(BuildContext context) {
    return tasksAsync.when(
      data: (tasks) {
        final total = tasks.where((t) => t.parentId == null).length;
        final completed = tasks
            .where((t) => t.isCompleted && t.parentId == null)
            .length;
        final today = tasks.where((t) {
          if (t.due == null || t.parentId != null) return false;
          final today = DateTime.now();
          return t.due!.year == today.year &&
              t.due!.month == today.month &&
              t.due!.day == today.day;
        }).length;

        if (total == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2040),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Tasks',
                value: '$total',
                icon: Icons.check_circle_outline,
              ),
              _StatItem(
                label: 'Completed',
                value: '$completed',
                icon: Icons.check_circle,
              ),
              if (today > 0)
                _StatItem(
                  label: 'Due Today',
                  value: '$today',
                  icon: Icons.today,
                  highlight: true,
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8C8A97)),
        ),
      ],
    );
  }
}

/// Single task row with GlassCard styling
class _TaskRow extends StatelessWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const _TaskRow({
    required this.task,
    this.isSelected = false,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? AppColors.primary
                            : const Color(0xFF5C5C5C),
                        width: 2,
                      ),
                      boxShadow: task.isCompleted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Task content
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted
                          ? AppColors.textHint
                          : const Color(0xFFEBEBEB),
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // Due date
                if (task.due != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(task.due!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                // Star
                if (task.isStarred) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    return '${date.month}/${date.day}';
  }
}

/// Add task input at TOP of list - GlassCard row
class _AddTaskInput extends ConsumerStatefulWidget {
  final String listId;

  const _AddTaskInput({required this.listId});

  @override
  ConsumerState<_AddTaskInput> createState() => _AddTaskInputState();
}

class _AddTaskInputState extends ConsumerState<_AddTaskInput> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final id = const Uuid().v4();
      final newTask = Task(
        id: id,
        title: title,
        updated: DateTime.now(),
        taskListId: widget.listId,
      );
      await ref
          .read(tasksNotifierProvider(widget.listId).notifier)
          .createTask(newTask);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _addTask,
              child: const Icon(
                Icons.add,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Add a task...',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _addTask(),
              enabled: !_isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
