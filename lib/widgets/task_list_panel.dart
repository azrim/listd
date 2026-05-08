import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';

/// Filter the aggregate task stream into the slice that belongs to a virtual
/// list (My Day / Important / Planned / Tasks).
List<Task> _filterForVirtualList(List<Task> all, String listId) {
  final today = DateTime.now();
  bool sameDay(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;

  switch (listId) {
    case SpecialListIds.myDay:
      return all.where((t) => t.due != null && sameDay(t.due!)).toList();
    case SpecialListIds.important:
      return all.where((t) => t.isStarred).toList();
    case SpecialListIds.planned:
      return all.where((t) => t.due != null).toList();
    case SpecialListIds.tasks:
      return all;
    default:
      return all;
  }
}

/// Pick the list that "Add a task" on a virtual screen should write to.
/// Prefers the user's default list, then falls back to the first list.
TaskList? _resolveTargetList(List<TaskList> lists) {
  if (lists.isEmpty) return null;
  final defaults = lists.where((l) => l.isDefault);
  return defaults.isNotEmpty ? defaults.first : lists.first;
}

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

  bool get _isVirtual => listId.startsWith('@');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = _isVirtual
        ? ref
              .watch(allTasksProvider)
              .whenData((all) => _filterForVirtualList(all, listId))
        : ref.watch(tasksNotifierProvider(listId));
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        children: [
          _buildHeader(context, ref),
          _StatsStrip(tasksAsync: tasksAsync),
          _AddTaskInput(listId: listId),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) =>
                  _buildContent(context, ref, tasks, selectedTaskId),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(context, ref, e),
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger a fresh fetch. Virtual lists ask every real list to resync,
  /// since the aggregate is computed from those.
  Future<void> _refresh(WidgetRef ref) async {
    if (!_isVirtual) {
      await ref.read(tasksNotifierProvider(listId).notifier).syncFromRemote();
      return;
    }
    final lists = ref.read(taskListsNotifierProvider).valueOrNull ?? const [];
    await Future.wait(
      lists.map(
        (l) => ref.read(tasksNotifierProvider(l.id).notifier).syncFromRemote(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              listName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: scheme.onSurfaceVariant,
            onPressed: () => _refresh(ref),
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
      onRefresh: () => _refresh(ref),
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: mainTasks.length,
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          // Mutations always target the task's real owning list, not the
          // virtual screen the user happens to be viewing.
          final ownerListId = task.taskListId;
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
                  .read(tasksNotifierProvider(ownerListId).notifier)
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
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
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
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(tasksNotifierProvider(task.taskListId).notifier)
          .deleteTask(task.id);
    }
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks',
            style: TextStyle(color: scheme.onSurface),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a task above',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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

        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant, width: 1),
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
    final scheme = Theme.of(context).colorScheme;
    final color = highlight ? scheme.primary : scheme.onSurfaceVariant;
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
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.15),
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
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? scheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? scheme.primary
                            : scheme.outline,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? Icon(Icons.check, size: 13, color: scheme.onPrimary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (task.due != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(task.due!),
                      style: TextStyle(fontSize: 11, color: scheme.primary),
                    ),
                  ),
                if (task.isStarred) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 18, color: scheme.tertiary),
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

    // Resolve the real list to write into. Synthetic list IDs are not valid
    // foreign keys for the tasks table, so always route to a real list and
    // apply the right metadata so the task still surfaces in the virtual view.
    String targetListId = widget.listId;
    DateTime? defaultDue;
    bool defaultStarred = false;

    if (widget.listId.startsWith('@')) {
      final lists =
          ref.read(taskListsNotifierProvider).valueOrNull ?? const <TaskList>[];
      final target = _resolveTargetList(lists);
      if (target == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create a list first to add tasks here'),
            ),
          );
        }
        return;
      }
      targetListId = target.id;
      if (widget.listId == SpecialListIds.myDay) {
        final now = DateTime.now();
        defaultDue = DateTime(now.year, now.month, now.day);
      } else if (widget.listId == SpecialListIds.important) {
        defaultStarred = true;
      }
    }

    setState(() => _isLoading = true);
    try {
      final id = const Uuid().v4();
      final newTask = Task(
        id: id,
        title: title,
        updated: DateTime.now(),
        taskListId: targetListId,
        due: defaultDue,
        isStarred: defaultStarred,
      );
      await ref
          .read(tasksNotifierProvider(targetListId).notifier)
          .createTask(newTask);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          if (_isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _addTask,
              child: Icon(Icons.add, size: 24, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Add a task...',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
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
