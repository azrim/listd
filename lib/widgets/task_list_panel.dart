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
    final viewMode = ref.watch(taskViewModeProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);

    return Column(
      children: [
        // Header
        _buildHeader(context, ref),
        // Task list with pull-to-refresh
        Expanded(
          child: tasksAsync.when(
            data: (tasks) => _buildTaskList(context, ref, tasks, viewMode, selectedTaskId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref, e),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(taskViewModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(128),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  listName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // View toggle
              SegmentedButton<TaskViewMode>(
                segments: const [
                  ButtonSegment(
                    value: TaskViewMode.list,
                    icon: Icon(Icons.view_list, size: 18),
                  ),
                  ButtonSegment(
                    value: TaskViewMode.grid,
                    icon: Icon(Icons.grid_view, size: 18),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (selection) {
                  ref.read(taskViewModeProvider.notifier).state = selection.first;
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => ref.read(tasksNotifierProvider(listId).notifier).syncFromRemote(),
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
              ),
              // More options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) => _handleMenuAction(context, ref, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'clear', child: Text('Clear completed')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'clear') {
      // Clear completed tasks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clear completed (not implemented)')),
      );
    }
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(tasksNotifierProvider(listId).notifier).syncFromRemote(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    TaskViewMode viewMode,
    String? selectedTaskId,
  ) {
    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    // Filter for main tasks (not subtasks)
    final mainTasks = tasks.where((t) => t.parentId == null).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksNotifierProvider(listId).notifier).syncFromRemote(),
      child: Stack(
        children: [
          viewMode == TaskViewMode.grid
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: mainTasks.length,
                  itemBuilder: (context, index) {
                    final task = mainTasks[index];
                    return _TaskCard(
                      task: task,
                      isSelected: selectedTaskId == task.id,
                      onTap: () => ref.read(selectedTaskIdProvider.notifier).state = task.id,
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: mainTasks.length,
                  itemBuilder: (context, index) {
                    final task = mainTasks[index];
                    return _TaskRow(
                      task: task,
                      isSelected: selectedTaskId == task.id,
                      onTap: () => ref.read(selectedTaskIdProvider.notifier).state = task.id,
                      onToggle: () => ref.read(tasksNotifierProvider(listId).notifier).toggleComplete(task),
                      onDelete: () => _confirmDelete(context, ref, task),
                    );
                  },
                ),
          // Add task input at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AddTaskInput(listId: listId),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Task task) async {
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
      await ref.read(tasksNotifierProvider(listId).notifier).deleteTask(task.id);
    }
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
            'Add a task below to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Task row widget for list view
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
        return false; // Don't actually dismiss, let the callback handle it
      },
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withAlpha(77)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Checkbox circle
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
                        ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? colorScheme.outline : colorScheme.onSurface,
                        ),
                      ),
                      if (task.notes.isNotEmpty)
                        Text(
                          task.notes,
                          style: TextStyle(fontSize: 12, color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Due date chip
                if (task.due != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDueDateColor(context, task.due!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDueDate(task.due!),
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Star/favorite icon
                Icon(
                  task.isStarred ? Icons.star : Icons.star_border,
                  size: 20,
                  color: task.isStarred ? Colors.amber : colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    if (diff < 0) return '${-diff} days ago';
    return '${date.month}/${date.day}';
  }

  Color _getDueDateColor(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final diff = dueDay.difference(today).inDays;

    if (diff < 0) {
      return Theme.of(context).colorScheme.errorContainer;
    } else if (diff == 0) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }
}

/// Task card widget for grid view
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isSelected,
    this.onTap,
  });

  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: task.isCompleted ? colorScheme.primary : colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? colorScheme.outline : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.isStarred) const Icon(Icons.star, size: 16, color: Colors.amber),
                ],
              ),
              if (task.due != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDueDate(task.due!),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// Add task input widget
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
        id: '', // Empty ID for new tasks
        title: title,
        status: 'needsAction',
        updated: DateTime.now(),
        taskListId: widget.listId,
      );

      await ref.read(tasksNotifierProvider(widget.listId).notifier).createTask(newTask);

      _controller.clear();
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  visualDensity: VisualDensity.compact,
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
