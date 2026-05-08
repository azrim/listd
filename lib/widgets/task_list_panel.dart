import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_colors.dart';

/// Main task list panel showing tasks in a selected list - glassmorphism style
class TaskListPanel extends ConsumerWidget {
  final String listId;
  final String listName;

  const TaskListPanel({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider(listId));
    final selectedTaskId = ref.watch(selectedTaskIdProvider);

    return Column(
      children: [
        // Header with glass effect
        _buildHeader(context, ref),
        // Task list with pull-to-refresh
        Expanded(
          child: tasksAsync.when(
            data: (tasks) => _buildContent(context, ref, tasks, selectedTaskId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref, e),
          ),
        ),
        // Add task input (always visible at bottom)
        _AddTaskInput(listId: listId),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withAlpha(128), // 50% opacity
            border: const Border(
              bottom: BorderSide(color: Colors.white10, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  listName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
        ),
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
              onTap: () =>
                  ref.read(selectedTaskIdProvider.notifier).state = task.id,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No tasks yet',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a task below',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphism task row widget
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isSelected,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(179),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        onDelete?.call();
        return false;
      },
      child: Material(
        color: isSelected
            ? AppColors.primary.withAlpha(51) // 20% opacity
            : Colors.white.withAlpha(13), // 5% opacity
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? AppColors.primary
                            : AppColors.textHint,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (task.isStarred)
                  const Icon(Icons.star, size: 20, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Add task input widget - always visible at bottom with glass effect
class _AddTaskInput extends ConsumerStatefulWidget {
  const _AddTaskInput({required this.listId});

  final String listId;

  @override
  ConsumerState<_AddTaskInput> createState() => _AddTaskInputState();
}

class _AddTaskInputState extends ConsumerState<_AddTaskInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newTask = Task(
        id: '',
        title: title,
        status: 'needsAction',
        updated: DateTime.now(),
        taskListId: widget.listId,
      );

      await ref
          .read(tasksNotifierProvider(widget.listId).notifier)
          .createTask(newTask);

      _controller.clear();
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withAlpha(179), // 70% opacity
            border: const Border(
              top: BorderSide(color: Colors.white10, width: 1),
            ),
          ),
          child: Row(
            children: [
              _isLoading
                  ? const SizedBox(
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
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      color: AppColors.textSecondary,
                      onPressed: _addTask,
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a task',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTask(),
                  enabled: !_isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
