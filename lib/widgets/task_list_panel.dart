import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';

/// Main task list panel showing tasks in a selected list
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
        // Header
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(128),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              listName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
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
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: mainTasks.length,
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          return _TaskRow(
            task: task,
            isSelected: selectedTaskId == task.id,
            onTap: () =>
                ref.read(selectedTaskIdProvider.notifier).state = task.id,
            onToggle: () => ref
                .read(tasksNotifierProvider(listId).notifier)
                .toggleComplete(task),
            onDelete: () => _confirmDelete(context, ref, task),
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
        title: const Text('Delete task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks',
            style: Theme.of(context).textTheme.titleMedium,
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
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a task below',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Task row widget
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
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        onDelete?.call();
        return false;
      },
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withAlpha(77)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: colorScheme.onPrimary,
                          )
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
                          ? colorScheme.outline
                          : colorScheme.onSurface,
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

/// Add task input widget - always visible at bottom
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  onPressed: _addTask,
                ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Add a task',
                border: InputBorder.none,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                isDense: true,
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
