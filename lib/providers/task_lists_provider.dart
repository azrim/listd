import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart' hide databaseProvider;
import '../data/database/daos/task_list_dao.dart';
import '../models/task_list.dart';
import '../services/auth/token_manager.dart';
import '../services/tasks/google_tasks_api.dart';

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

/// Future provider that fetches task lists from Google API with auth.
final remoteTaskListsProvider = FutureProvider<List<TaskList>>((ref) async {
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
  final taskLists = await api.getTaskLists();

  // Mark as synced and save to local DB
  final syncedLists = taskLists
      .map((tl) => tl.copyWith(syncStatus: tl.syncStatus))
      .toList();

  // Save to local database
  final dao = ref.read(taskListDaoProvider);
  await dao.upsertTaskLists(syncedLists);

  return syncedLists;
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
  final Ref _ref;

  TaskListsNotifier({required TaskListDao dao, required Ref ref})
    : _dao = dao,
      _ref = ref,
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
    state = const AsyncValue.loading();
    try {
      // Get auth state
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        // Not authenticated, just refresh local data
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
      final remoteLists = await api.getTaskLists();

      // Save to local database
      await _dao.upsertTaskLists(remoteLists);

      // Update state
      state = AsyncValue.data(remoteLists);
    } catch (e) {
      // Keep local data if remote sync fails
      await refresh();
    }
  }
}

/// Provider for the TaskListsNotifier.
final taskListsNotifierProvider =
    StateNotifierProvider<TaskListsNotifier, AsyncValue<List<TaskList>>>((ref) {
      final dao = ref.watch(taskListDaoProvider);
      return TaskListsNotifier(dao: dao, ref: ref);
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
