import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart' hide databaseProvider;
import '../data/database/daos/task_list_dao.dart';
import '../data/database/daos/task_dao.dart';
import '../models/sync_status.dart';
import '../models/task_list.dart';
import '../services/auth/token_manager.dart';
import '../services/sync/task_sync_service.dart';
import '../services/tasks/supabase_tasks_provider.dart';
import '../services/supabase/supabase_client_service.dart'
    show supabaseClientProvider;

/// Provider for the database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for the [TaskListDao].
final taskListDaoProvider = Provider<TaskListDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskListDao(db);
});

/// Provider for the [TaskDao].
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskDao(db);
});

/// Provider for [SupabaseTasksProvider].
final supabaseTasksProviderProvider = Provider<SupabaseTasksProvider>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseTasksProvider(client);
});

/// Background sync service. UI code shouldn't depend on this directly —
/// notifiers call `scheduleSync()` after each local mutation.
final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  return TaskSyncService(
    taskDao: ref.watch(taskDaoProvider),
    taskListDao: ref.watch(taskListDaoProvider),
    taskProvider: ref.watch(supabaseTasksProviderProvider),
  );
});

/// Streams the live list of task lists from Drift. This is the single
/// source of truth that the UI subscribes to.
final taskListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  final dao = ref.watch(taskListDaoProvider);
  return dao.watchAllTaskLists().map(
    (entries) => entries.map((e) => e.toDomain()).toList(),
  );
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

/// Notifier for task list mutations. Writes go to Drift first; a
/// background push to Supabase is scheduled but not awaited.
class TaskListsNotifier extends StateNotifier<AsyncValue<List<TaskList>>> {
  TaskListsNotifier({required Ref ref})
    : _ref = ref,
      super(const AsyncValue.loading()) {
    _attachStream();
    // Kick off an initial pull from Supabase. The stream will reflect
    // any new rows as soon as the sync upserts them.
    _ref.read(taskSyncServiceProvider).scheduleSync();

    // Re-sync when auth flips to authenticated.
    _ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next is AuthAuthenticated && prev is! AuthAuthenticated) {
        _ref.read(taskSyncServiceProvider).scheduleSync();
      }
    });
  }

  final Ref _ref;
  StreamSubscription<List<TaskList>>? _sub;

  void _attachStream() {
    final dao = _ref.read(taskListDaoProvider);
    _sub = dao
        .watchAllTaskLists()
        .map((entries) => entries.map((e) => e.toDomain()).toList())
        .listen(
          (lists) {
            if (!mounted) return;
            state = AsyncValue.data(lists);
          },
          onError: (Object e, StackTrace st) {
            if (!mounted) return;
            state = AsyncValue.error(e, st);
          },
        );
  }

  /// Forces a remote sync. Drift will reflect any changes via the stream.
  Future<void> refresh() async {
    await _ref.read(taskSyncServiceProvider).syncAll();
  }

  /// Backwards-compat alias.
  Future<void> syncFromRemote() => refresh();

  /// Creates a new task list. Writes to Drift first, then triggers a
  /// background push to Supabase.
  Future<TaskList> createTaskList(String title) async {
    final auth = _ref.read(authNotifierProvider);
    final userId = auth is AuthAuthenticated ? auth.session.user.id : '';

    final taskList = TaskList(
      id: const Uuid().v4(),
      title: title,
      updated: DateTime.now(),
      syncStatus: SyncStatus.created,
      userId: userId,
    );

    await _ref.read(taskListDaoProvider).upsertTaskList(taskList);
    _ref.read(taskSyncServiceProvider).scheduleSync();
    return taskList;
  }

  /// Updates the title or default flag of a task list.
  Future<void> updateTaskList(TaskList taskList) async {
    final dao = _ref.read(taskListDaoProvider);
    final existing = await dao.getTaskList(taskList.id);
    // Preserve `created` so we don't downgrade a never-pushed row.
    final next = taskList.copyWith(
      syncStatus: existing?.syncStatus == SyncStatus.created.value
          ? SyncStatus.created
          : SyncStatus.updated,
      updated: DateTime.now(),
    );
    await dao.upsertTaskList(next);
    _ref.read(taskSyncServiceProvider).scheduleSync();
  }

  /// Deletes a task list. Marks tombstone locally; the actual remote
  /// delete + Drift hard-delete happens during the next sync.
  Future<void> deleteTaskList(String id) async {
    final dao = _ref.read(taskListDaoProvider);
    final existing = await dao.getTaskList(id);
    if (existing == null) return;
    if (existing.syncStatus == SyncStatus.created.value) {
      // Never-pushed: just hard-delete locally.
      await dao.deleteTaskList(id);
      await _ref.read(taskDaoProvider).deleteTasksByListId(id);
    } else {
      await dao.markDeletedLocally(id);
    }
    _ref.read(taskSyncServiceProvider).scheduleSync();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Provider for [TaskListsNotifier].
final taskListsNotifierProvider =
    StateNotifierProvider<TaskListsNotifier, AsyncValue<List<TaskList>>>((ref) {
      return TaskListsNotifier(ref: ref);
    });
