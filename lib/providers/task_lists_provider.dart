import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart' hide databaseProvider;
import '../data/database/daos/task_list_dao.dart';
import '../models/task_list.dart';
import '../services/auth/token_manager.dart';
import '../services/tasks/supabase_tasks_provider.dart';
import '../services/supabase/supabase_client_service.dart' show supabaseClientProvider;

/// Provider for the database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for the TaskListDao.
final taskListDaoProvider = Provider<TaskListDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskListDao(db);
});

/// Provider for SupabaseTasksProvider.
final supabaseTasksProviderProvider = Provider<SupabaseTasksProvider>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseTasksProvider(client);
});

/// Stream provider that watches all task lists from the local database.
final taskListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  final dao = ref.watch(taskListDaoProvider);
  return dao.watchAllTaskLists().map(
    (entries) => entries.map((e) => e.toDomain()).toList(),
  );
});

/// Future provider that fetches task lists from Supabase with auth.
final remoteTaskListsProvider = FutureProvider<List<TaskList>>((ref) async {
  // Wait for auth state to be ready
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    return [];
  }

  // Use SupabaseTasksProvider to fetch task lists
  final provider = ref.watch(supabaseTasksProviderProvider);
  final taskLists = await provider.getTaskLists();

  // Save to local database for offline access
  final dao = ref.read(taskListDaoProvider);
  await dao.upsertTaskLists(taskLists);

  return taskLists;
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

  /// Syncs task lists from Supabase and saves to local database.
  Future<void> syncFromRemote() async {
    state = const AsyncValue.loading();
    try {
      // Get auth state
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        await refresh();
        return;
      }

      // Use SupabaseTasksProvider to sync
      final provider = _ref.read(supabaseTasksProviderProvider);
      final remoteLists = await provider.getTaskLists();

      // Save to local database
      await _dao.upsertTaskLists(remoteLists);

      // Update state
      state = AsyncValue.data(remoteLists);
    } catch (e) {
      await refresh();
    }
  }

  /// Creates a new task list and syncs to Supabase.
  Future<void> createTaskList(String title) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      // Create via Supabase
      final provider = _ref.read(supabaseTasksProviderProvider);
      final newList = await provider.createTaskList(title);

      // Save to local database
      await _dao.upsertTaskLists([newList]);

      // Refresh
      await refresh();
    } catch (e) {
      await refresh();
    }
  }

  /// Deletes a task list.
  Future<void> deleteTaskList(String id) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      // Delete via Supabase
      final provider = _ref.read(supabaseTasksProviderProvider);
      await provider.deleteTaskList(id);

      // Remove from local database
      await _dao.deleteTaskList(id);

      // Refresh
      await refresh();
    } catch (e) {
      // Ignore errors
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

  return localAsync.when(
    data: (localLists) async {
      if (localLists.isNotEmpty) {
        return localLists;
      }
      return remoteAsync.when(
        data: (remoteLists) => remoteLists,
        loading: () => localLists,
        error: (_, _) => localLists,
      );
    },
    loading: () => remoteAsync.when(
      data: (remoteLists) => remoteLists,
      loading: () => <TaskList>[],
      error: (_, _) => <TaskList>[],
    ),
    error: (_, _) => remoteAsync.when(
      data: (remoteLists) => remoteLists,
      loading: () => <TaskList>[],
      error: (_, _) => <TaskList>[],
    ),
  );
});