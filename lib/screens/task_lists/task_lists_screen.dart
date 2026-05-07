import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../widgets/task_list_tile.dart';

/// Screen displaying all task lists.
class TaskListsScreen extends ConsumerWidget {
  const TaskListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Task Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: taskListsAsync.when(
        data: (taskLists) => _buildTaskList(context, ref, taskLists),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskList> taskLists,
  ) {
    if (taskLists.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final notifier = ref.read(taskListsNotifierProvider.notifier);
        await notifier.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: taskLists.length,
        itemBuilder: (context, index) {
          final taskList = taskLists[index];
          return TaskListTile(
            taskList: taskList,
            onTap: () => _navigateToTasks(context, taskList),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No task lists yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Google Tasks will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final notifier = ref.read(taskListsNotifierProvider.notifier);
              await notifier.syncFromRemote();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Sync from Google'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
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
              'Failed to load task lists',
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
              onPressed: () {
                final notifier = ref.read(taskListsNotifierProvider.notifier);
                notifier.refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTasks(BuildContext context, TaskList taskList) {
    context.go(
      '/tasks/${Uri.encodeComponent(taskList.id)}?title=${Uri.encodeComponent(taskList.title)}',
    );
  }
}
