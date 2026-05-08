import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/daos/task_dao.dart';
import '../models/task.dart';
import '../services/auth/token_manager.dart';
import 'task_lists_provider.dart'
    show databaseProvider, supabaseTasksProviderProvider;

/// Provider for the TaskDao.
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskDao(db);
});

/// Trigger to refresh tasks for a specific list
final tasksRefreshProvider = StateProvider.family<int, String>(
  (ref, listId) => 0,
);

/// Stream provider that syncs tasks from Supabase for a specific task list.
final tasksStreamProvider = StreamProvider.family<List<Task>, String>((
  ref,
  taskListId,
) async* {
  // Watch the refresh trigger
  ref.watch(tasksRefreshProvider(taskListId));

  final authState = ref.watch(authNotifierProvider);
  final dao = ref.watch(taskDaoProvider);

  // Skip special list IDs
  if (taskListId.startsWith('@')) {
    yield [];
    return;
  }

  if (authState is! AuthAuthenticated) {
    try {
      final localTasks = await dao.getTasksByListId(taskListId);
      yield localTasks.map((e) => e.toDomain()).toList();
    } catch (_) {
      yield [];
    }
    return;
  }

  try {
    final provider = ref.read(supabaseTasksProviderProvider);
    final remoteTasks = await provider.getTasks(taskListId);

    if (remoteTasks.isNotEmpty) {
      await dao.upsertTasks(remoteTasks);
    }

    yield remoteTasks;
  } catch (_) {
    yield [];
  }
});

/// Future provider that fetches tasks from Supabase for a specific task list.
final remoteTasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  taskListId,
) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    return [];
  }

  final provider = ref.watch(supabaseTasksProviderProvider);
  return provider.getTasks(taskListId);
});

/// Notifier for managing tasks state for a specific task list.
class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final Ref _ref;
  final String taskListId;

  TasksNotifier({required Ref ref, required this.taskListId})
    : _ref = ref,
      super(const AsyncValue.loading()) {
    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    if (taskListId.startsWith('@')) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        state = const AsyncValue.data([]);
        return;
      }

      final provider = _ref.read(supabaseTasksProviderProvider);
      final remoteTasks = await provider.getTasks(taskListId);

      state = AsyncValue.data(remoteTasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _ref.read(tasksRefreshProvider(taskListId).notifier).state++;
  }

  Future<void> syncFromRemote() async {
    _ref.read(tasksRefreshProvider(taskListId).notifier).state++;
    await _syncFromRemote();
  }

  Future<void> createTask(Task task) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      final taskWithId = task.id.isEmpty
          ? task.copyWith(id: const Uuid().v4())
          : task;

      final provider = _ref.read(supabaseTasksProviderProvider);
      await provider.createTask(taskListId, taskWithId);

      // Trigger stream refresh
      _ref.read(tasksRefreshProvider(taskListId).notifier).state++;

      // Also refresh this notifier
      await _syncFromRemote();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      final provider = _ref.read(supabaseTasksProviderProvider);
      await provider.updateTask(taskListId, task);

      _ref.read(tasksRefreshProvider(taskListId).notifier).state++;
      await _syncFromRemote();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleComplete(Task task) async {
    final newStatus = task.isCompleted ? 'needsAction' : 'completed';
    final updatedTask = task.copyWith(status: newStatus);
    await updateTask(updatedTask);
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      final provider = _ref.read(supabaseTasksProviderProvider);
      await provider.deleteTask(taskListId, taskId);

      _ref.read(tasksRefreshProvider(taskListId).notifier).state++;
      await _syncFromRemote();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Family provider for TasksNotifier.
final tasksNotifierProvider =
    StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>(
      (ref, taskListId) {
        return TasksNotifier(ref: ref, taskListId: taskListId);
      },
    );

/// Convenience provider that combines local and remote tasks.
final tasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  taskListId,
) async {
  final localAsync = ref.watch(tasksStreamProvider(taskListId));
  final remoteAsync = ref.watch(remoteTasksProvider(taskListId));

  return localAsync.when(
    data: (localTasks) async {
      if (localTasks.isNotEmpty) {
        return localTasks;
      }
      return remoteAsync.when(
        data: (remoteTasks) => remoteTasks,
        loading: () => localTasks,
        error: (_, _) => localTasks,
      );
    },
    loading: () => remoteAsync.when(
      data: (remoteTasks) => remoteTasks,
      loading: () => <Task>[],
      error: (_, _) => <Task>[],
    ),
    error: (_, _) => remoteAsync.when(
      data: (remoteTasks) => remoteTasks,
      loading: () => <Task>[],
      error: (_, _) => <Task>[],
    ),
  );
});
