import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/daos/task_dao.dart';
import '../models/task.dart';
import '../models/sync_status.dart';
import '../services/tasks/google_tasks_provider.dart' show googleTasksProvider;
import 'task_lists_provider.dart' show databaseProvider;

/// Provider for the TaskDao.
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskDao(db);
});

/// Stream provider that watches tasks for a specific task list from local database.
final tasksStreamProvider = StreamProvider.family<List<Task>, String>((
  ref,
  taskListId,
) {
  final dao = ref.watch(taskDaoProvider);
  return dao
      .watchTasksByListId(taskListId)
      .map((entries) => entries.map((e) => e.toDomain()).toList());
});

/// Future provider that fetches tasks from Google API for a specific task list.
final remoteTasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  taskListId,
) async {
  final provider = ref.watch(googleTasksProvider);
  return provider.getTasks(taskListId);
});

/// Notifier for managing tasks state for a specific task list.
class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskDao _dao;
  final String taskListId;

  TasksNotifier({required TaskDao dao, required this.taskListId})
    : _dao = dao,
      super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _dao.getTasksByListId(taskListId);
      state = AsyncValue.data(tasks.map((e) => e.toDomain()).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refreshes tasks from the local database.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _dao.getTasksByListId(taskListId);
      state = AsyncValue.data(tasks.map((e) => e.toDomain()).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a new task and saves to local database.
  Future<void> createTask(Task task) async {
    try {
      final newTask = task.copyWith(
        id: task.id.isEmpty ? const Uuid().v4() : task.id,
        updated: DateTime.now(),
        syncStatus: SyncStatus.created,
      );
      await _dao.upsertTask(newTask);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates an existing task.
  Future<void> updateTask(Task task) async {
    try {
      final updatedTask = task.copyWith(
        updated: DateTime.now(),
        syncStatus: SyncStatus.updated,
      );
      await _dao.upsertTask(updatedTask);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggles task completion status.
  Future<void> toggleComplete(Task task) async {
    try {
      final newStatus = task.isCompleted ? 'needsAction' : 'completed';
      final updatedTask = task.copyWith(
        status: newStatus,
        updated: DateTime.now(),
        syncStatus: SyncStatus.updated,
      );
      await _dao.upsertTask(updatedTask);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Marks a task as deleted (soft delete).
  Future<void> deleteTask(String taskId) async {
    try {
      await _dao.markDeletedLocally(taskId);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Syncs tasks from remote and saves to local database.
  Future<void> syncFromRemote() async {
    try {
      // Note: This is a placeholder for sync functionality
      // Actual implementation would use the sync service
    } catch (e) {
      // Keep local data if remote sync fails
    }
  }
}

/// Family provider for TasksNotifier.
final tasksNotifierProvider =
    StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>(
      (ref, taskListId) {
        final dao = ref.watch(taskDaoProvider);
        return TasksNotifier(dao: dao, taskListId: taskListId);
      },
    );

/// Convenience provider that combines local and remote tasks.
/// Prefers local data, falls back to remote if local is empty.
final tasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  taskListId,
) async {
  final localAsync = ref.watch(tasksStreamProvider(taskListId));
  final remoteAsync = ref.watch(remoteTasksProvider(taskListId));

  // Return local data if available
  return localAsync.when(
    data: (localTasks) async {
      if (localTasks.isNotEmpty) {
        return localTasks;
      }
      // Try remote if local is empty
      return remoteAsync.when(
        data: (remoteTasks) => remoteTasks,
        loading: () => localTasks,
        error: (_, _) => localTasks,
      );
    },
    loading: () => remoteAsync.when(
      data: (remoteTasks) => remoteTasks,
      loading: () => [],
      error: (_, _) => [],
    ),
    error: (_, _) => remoteAsync.when(
      data: (remoteTasks) => remoteTasks,
      loading: () => [],
      error: (_, _) => [],
    ),
  );
});
