import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/daos/task_dao.dart';
import '../models/task.dart';
import '../models/sync_status.dart';
import '../services/auth/token_manager.dart';
import '../services/tasks/google_tasks_api.dart';
import 'task_lists_provider.dart' show databaseProvider;

/// Provider for the TaskDao.
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskDao(db);
});

/// Stream provider that watches tasks for a specific task list from local database.
final tasksStreamProvider = StreamProvider.family<List<Task>, String>((ref, taskListId) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchTasksByListId(taskListId).map(
    (entries) => entries.map((e) => e.toDomain()).toList(),
  );
});

/// Future provider that fetches tasks from Google API for a specific task list.
final remoteTasksProvider = FutureProvider.family<List<Task>, String>((ref, taskListId) async {
  // Wait for auth state to be ready
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    return [];
  }

  // Get valid access token
  final tokenManager = ref.watch(tokenManagerProvider);
  final accessToken = await tokenManager.getValidAccessToken();
  if (accessToken == null) {
    return [];
  }

  // Call the API
  final api = GoogleTasksApi(accessToken: accessToken);
  final tasks = await api.getTasks(taskListId);

  // Save to local database
  final dao = ref.read(taskDaoProvider);
  await dao.upsertTasks(tasks);

  return tasks;
});

/// Notifier for managing tasks state for a specific task list.
class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskDao _dao;
  final String taskListId;
  final Ref _ref;

  TasksNotifier({
    required TaskDao dao,
    required this.taskListId,
    required Ref ref,
  })  : _dao = dao,
        _ref = ref,
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

  /// Creates a new task via Google API and saves to local database.
  Future<void> createTask(Task task) async {
    try {
      // Get auth state
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        // Save locally if not authenticated
        final newTask = task.copyWith(
          id: task.id.isEmpty ? const Uuid().v4() : task.id,
          updated: DateTime.now(),
          syncStatus: SyncStatus.created,
        );
        await _dao.upsertTask(newTask);
        await refresh();
        return;
      }

      // Get valid access token
      final tokenManager = _ref.read(tokenManagerProvider);
      final accessToken = await tokenManager.getValidAccessToken();
      if (accessToken == null) {
        // Save locally if no token
        final newTask = task.copyWith(
          id: task.id.isEmpty ? const Uuid().v4() : task.id,
          updated: DateTime.now(),
          syncStatus: SyncStatus.created,
        );
        await _dao.upsertTask(newTask);
        await refresh();
        return;
      }

      // Call Google API
      final api = GoogleTasksApi(accessToken: accessToken);
      final createdTask = await api.createTask(taskListId, task);
      
      // Save to local database
      await _dao.upsertTask(createdTask);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates an existing task via Google API.
  Future<void> updateTask(Task task) async {
    try {
      // Get auth state
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        // Save locally if not authenticated
        final updatedTask = task.copyWith(
          updated: DateTime.now(),
          syncStatus: SyncStatus.updated,
        );
        await _dao.upsertTask(updatedTask);
        await refresh();
        return;
      }

      // Get valid access token
      final tokenManager = _ref.read(tokenManagerProvider);
      final accessToken = await tokenManager.getValidAccessToken();
      if (accessToken == null) {
        // Save locally if no token
        final updatedTask = task.copyWith(
          updated: DateTime.now(),
          syncStatus: SyncStatus.updated,
        );
        await _dao.upsertTask(updatedTask);
        await refresh();
        return;
      }

      // Call Google API
      final api = GoogleTasksApi(accessToken: accessToken);
      final updatedTask = await api.updateTask(taskListId, task);
      
      // Save to local database
      await _dao.upsertTask(updatedTask);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggles task completion status.
  Future<void> toggleComplete(Task task) async {
    final newStatus = task.isCompleted ? 'needsAction' : 'completed';
    final updatedTask = task.copyWith(status: newStatus);
    await updateTask(updatedTask);
  }

  /// Deletes a task via Google API.
  Future<void> deleteTask(String taskId) async {
    try {
      // Get auth state
      final authState = _ref.read(authNotifierProvider);
      
      if (authState is AuthAuthenticated) {
        // Try to delete from Google API
        try {
          final tokenManager = _ref.read(tokenManagerProvider);
          final accessToken = await tokenManager.getValidAccessToken();
          if (accessToken != null) {
            final api = GoogleTasksApi(accessToken: accessToken);
            await api.deleteTask(taskListId, taskId);
          }
        } catch (_) {
          // If API fails, continue with local delete
        }
      }

      // Delete from local database
      await _dao.deleteTask(taskId);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Syncs tasks from remote and saves to local database.
  Future<void> syncFromRemote() async {
    state = const AsyncValue.loading();
    try {
      // Get auth state
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        await refresh();
        return;
      }

      // Get valid access token
      final tokenManager = _ref.read(tokenManagerProvider);
      final accessToken = await tokenManager.getValidAccessToken();
      if (accessToken == null) {
        await refresh();
        return;
      }

      // Call the API
      final api = GoogleTasksApi(accessToken: accessToken);
      final remoteTasks = await api.getTasks(taskListId);

      // Save to local database
      await _dao.upsertTasks(remoteTasks);

      // Update state
      state = AsyncValue.data(remoteTasks);
    } catch (e) {
      await refresh();
    }
  }
}

/// Family provider for TasksNotifier.
final tasksNotifierProvider = StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>((ref, taskListId) {
  final dao = ref.watch(taskDaoProvider);
  return TasksNotifier(dao: dao, taskListId: taskListId, ref: ref);
});

/// Convenience provider that combines local and remote tasks.
final tasksProvider = FutureProvider.family<List<Task>, String>((ref, taskListId) async {
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
