import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/task_tile.dart';

/// Screen displaying tasks within a task list.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({
    super.key,
    required this.taskListId,
    required this.taskListTitle,
  });

  final String taskListId;
  final String taskListTitle;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider(widget.taskListId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(widget.taskListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshTasks(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) => _buildTaskList(tasks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskTile(
            task: task,
            onToggle: () => _toggleTask(task),
            onDelete: () => _deleteTask(task),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
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
            'Tap + to add a new task',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshTasks() async {
    final notifier = ref.read(
      tasksNotifierProvider(widget.taskListId).notifier,
    );
    await notifier.refresh();
  }

  Future<void> _toggleTask(Task task) async {
    final notifier = ref.read(
      tasksNotifierProvider(widget.taskListId).notifier,
    );
    await notifier.toggleComplete(task);
  }

  Future<void> _deleteTask(Task task) async {
    final notifier = ref.read(
      tasksNotifierProvider(widget.taskListId).notifier,
    );
    await notifier.deleteTask(task.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Re-add the task
              final notifier = ref.read(
                tasksNotifierProvider(widget.taskListId).notifier,
              );
              notifier.createTask(task);
            },
          ),
        ),
      );
    }
  }

  Future<void> _showAddTaskDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task title'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final notifier = ref.read(
        tasksNotifierProvider(widget.taskListId).notifier,
      );
      final newTask = Task(
        id: '',
        title: result,
        updated: DateTime.now(),
        taskListId: widget.taskListId,
      );
      await notifier.createTask(newTask);
    }
  }
}
