import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        // Task list
        Expanded(
          child: tasksAsync.when(
            data: (tasks) =>
                _buildTaskList(context, ref, tasks, viewMode, selectedTaskId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
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
                  ref.read(taskViewModeProvider.notifier).state =
                      selection.first;
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Sort button
              IconButton(
                icon: const Icon(Icons.sort, size: 20),
                onPressed: () {},
                tooltip: 'Sort',
                visualDensity: VisualDensity.compact,
              ),
              // Group button
              IconButton(
                icon: const Icon(Icons.group_work_outlined, size: 20),
                onPressed: () {},
                tooltip: 'Group',
                visualDensity: VisualDensity.compact,
              ),
              // Share button
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () {},
                tooltip: 'Share',
                visualDensity: VisualDensity.compact,
              ),
              // More options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {},
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'select', child: Text('Select')),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear completed'),
                  ),
                ],
              ),
            ],
          ),
        ],
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
              'Add a task to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Filter for main tasks (not subtasks)
    final mainTasks = tasks.where((t) => t.parentId == null).toList();

    return Stack(
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
                itemBuilder: (context, index) => _TaskCard(
                  task: mainTasks[index],
                  isSelected: selectedTaskId == mainTasks[index].id,
                  onTap: () => ref.read(selectedTaskIdProvider.notifier).state =
                      mainTasks[index].id,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: mainTasks.length,
                itemBuilder: (context, index) => _TaskRow(
                  task: mainTasks[index],
                  isSelected: selectedTaskId == mainTasks[index].id,
                  onTap: () => ref.read(selectedTaskIdProvider.notifier).state =
                      mainTasks[index].id,
                  onToggle: () => _toggleTask(ref, mainTasks[index]),
                ),
              ),
        // Add task input at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _AddTaskInput(listId: listId),
        ),
      ],
    );
  }

  void _toggleTask(WidgetRef ref, Task task) {
    final notifier = ref.read(tasksNotifierProvider(listId).notifier);
    notifier.toggleComplete(task);
  }
}

/// Task row widget for list view
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isSelected,
    this.onTap,
    this.onToggle,
  });

  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
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
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
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
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? colorScheme.outline
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (task.subtaskCount > 0)
                      Text(
                        '0 of ${task.subtaskCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              // Due date chip
              if (task.due != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDueDateColor(context, task.due!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDueDate(task.due!),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface,
                    ),
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
    return DateFormat.MMMd().format(date);
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
  const _TaskCard({required this.task, required this.isSelected, this.onTap});

  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
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
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                    color: task.isCompleted
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.isStarred)
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                ],
              ),
              if (task.due != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDueDate(task.due!),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    return DateFormat.MMMd().format(date);
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      status: 'needsAction',
      updated: DateTime.now(),
      taskListId: widget.listId,
    );

    final notifier = ref.read(tasksNotifierProvider(widget.listId).notifier);
    await notifier.createTask(newTask);

    _controller.clear();
    _focusNode.requestFocus();
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
          IconButton(
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
              ),
              onSubmitted: (_) => _addTask(),
            ),
          ),
        ],
      ),
    );
  }
}
