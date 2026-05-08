import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart' hide databaseProvider;
import '../data/database/daos/task_list_dao.dart';
import '../models/task_list.dart';
import '../services/auth/token_manager.dart';
import '../services/tasks/supabase_tasks_provider.dart';
import '../services/supabase/supabase_client_service.dart'
    show supabaseClientProvider;

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

/// Trigger to refresh the task lists stream
final taskListsRefreshProvider = StateProvider<int>((ref) => 0);

/// Stream provider that syncs task lists from Supabase.
/// Refreshes when taskListsRefreshProvider changes.
final taskListsStreamProvider = StreamProvider<List<TaskList>>((ref) async* {
  // Watch the refresh trigger
  ref.watch(taskListsRefreshProvider);

  final authState = ref.watch(authNotifierProvider);

  if (authState is! AuthAuthenticated) {
    yield [];
    return;
  }

  print('taskListsStreamProvider: Syncing from Supabase');

  try {
    final provider = ref.read(supabaseTasksProviderProvider);
    final remoteLists = await provider.getTaskLists();
    print('taskListsStreamProvider: Got ${remoteLists.length} lists');
    yield remoteLists;
  } catch (e) {
    print('taskListsStreamProvider: Error - $e');
    yield [];
  }
});

/// Future provider that fetches task lists from Supabase with auth.
final remoteTaskListsProvider = FutureProvider<List<TaskList>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    return [];
  }

  final provider = ref.watch(supabaseTasksProviderProvider);
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
  final Ref _ref;

  TaskListsNotifier({required Ref ref})
    : _ref = ref,
      super(const AsyncValue.loading()) {
    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        state = const AsyncValue.data([]);
        return;
      }

      final provider = _ref.read(supabaseTasksProviderProvider);
      final remoteLists = await provider.getTaskLists();

      state = AsyncValue.data(remoteLists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _ref.read(taskListsRefreshProvider.notifier).state++;
  }

  Future<void> syncFromRemote() async {
    await _syncFromRemote();
  }

  Future<void> createTaskList(String title) async {
    print('TaskListsNotifier.createTaskList: $title');
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      final provider = _ref.read(supabaseTasksProviderProvider);
      print('TaskListsNotifier: Creating via Supabase...');
      await provider.createTaskList(title);
      print('TaskListsNotifier: Created');

      // Trigger stream refresh
      _ref.read(taskListsRefreshProvider.notifier).state++;

      // Also refresh state
      await _syncFromRemote();
    } catch (e) {
      print('TaskListsNotifier: Error - $e');
      await refresh();
    }
  }

  Future<void> deleteTaskList(String id) async {
    try {
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return;
      }

      final provider = _ref.read(supabaseTasksProviderProvider);
      await provider.deleteTaskList(id);

      await refresh();
    } catch (e) {
      // Ignore
    }
  }
}

/// Provider for the TaskListsNotifier.
final taskListsNotifierProvider =
    StateNotifierProvider<TaskListsNotifier, AsyncValue<List<TaskList>>>((ref) {
      return TaskListsNotifier(ref: ref);
    });

/// Convenience provider that combines local and remote task lists.
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
