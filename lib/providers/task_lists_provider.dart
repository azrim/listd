import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart' hide databaseProvider;
import '../data/database/daos/task_list_dao.dart';
import '../models/task_list.dart';
import '../services/tasks/google_tasks_provider.dart' show googleTasksProvider;

/// Provider for the database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for the TaskListDao.
final taskListDaoProvider = Provider<TaskListDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskListDao(db);
});

/// Stream provider that watches all task lists from the local database.
final taskListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  final dao = ref.watch(taskListDaoProvider);
  return dao.watchAllTaskLists().map(
    (entries) => entries.map((e) => e.toDomain()).toList(),
  );
});

/// Future provider that fetches task lists from Google API.
final remoteTaskListsProvider = FutureProvider<List<TaskList>>((ref) async {
  final provider = ref.watch(googleTasksProvider);
  return provider.getTaskLists();
});

/// Family provider that fetches a single task list by ID.
final taskListProvider = FutureProvider.family<TaskList?, String>((
  ref,
  id,
) async {
  final dao = ref.watch(taskListDaoProvider);
  final entry = await dao.getTaskList(id);
  return entry?.toDomain();
});

/// Notifier for managing task lists state.
class TaskListsNotifier extends StateNotifier<AsyncValue<List<TaskList>>> {
  final TaskListDao _dao;

  TaskListsNotifier({required TaskListDao dao})
    : _dao = dao,
      super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final taskLists = await _dao.getAllTaskLists();
      state = AsyncValue.data(taskLists.map((e) => e.toDomain()).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refreshes task lists from the local database.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final taskLists = await _dao.getAllTaskLists();
      state = AsyncValue.data(taskLists.map((e) => e.toDomain()).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Syncs task lists from remote and saves to local database.
  Future<void> syncFromRemote() async {
    try {
      // Note: Full sync would require auth token. This is a placeholder.
      // In production, this would use the GoogleTasksProvider with proper auth.
      await refresh();
    } catch (e) {
      // Keep local data if remote sync fails
      state = state;
    }
  }
}

/// Provider for the TaskListsNotifier.
final taskListsNotifierProvider =
    StateNotifierProvider<TaskListsNotifier, AsyncValue<List<TaskList>>>((ref) {
      final dao = ref.watch(taskListDaoProvider);
      return TaskListsNotifier(dao: dao);
    });

/// Convenience provider that combines local and remote task lists.
/// Prefers local data, falls back to remote if local is empty.
final taskListsProvider = FutureProvider<List<TaskList>>((ref) async {
  final localAsync = ref.watch(taskListsStreamProvider);
  final remoteAsync = ref.watch(remoteTaskListsProvider);

  // Return local data if available
  return localAsync.when(
    data: (localLists) async {
      if (localLists.isNotEmpty) {
        return localLists;
      }
      // Try remote if local is empty
      return remoteAsync.when(
        data: (remoteLists) => remoteLists,
        loading: () => localLists,
        error: (_, _) => localLists,
      );
    },
    loading: () => remoteAsync.when(
      data: (remoteLists) => remoteLists,
      loading: () => [],
      error: (_, _) => [],
    ),
    error: (_, _) => remoteAsync.when(
      data: (remoteLists) => remoteLists,
      loading: () => [],
      error: (_, _) => [],
    ),
  );
});
