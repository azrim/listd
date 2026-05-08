import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/daos/task_dao.dart';
import '../models/sync_status.dart';
import '../models/task.dart';
import '../services/auth/token_manager.dart';
import 'task_lists_provider.dart'
    show taskDaoProvider, taskListsNotifierProvider, taskSyncServiceProvider;

export 'task_lists_provider.dart' show taskDaoProvider;

/// Notifier for managing tasks state for a specific task list.
///
/// **Local-first**: subscribes to a Drift watch stream so the UI always
/// reflects the local database. Mutations write to Drift first with
/// the appropriate `syncStatus`, then a background sync pushes them up
/// to Supabase.
class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TasksNotifier({required Ref ref, required this.taskListId})
    : _ref = ref,
      super(const AsyncValue.loading()) {
    if (taskListId.startsWith('@')) {
      // Synthetic lists ("@my-day", "@important") have no own rows;
      // their contents come from `allTasksProvider` filtered in the UI.
      state = const AsyncValue.data([]);
      return;
    }
    _attachStream();
    _ref.read(taskSyncServiceProvider).scheduleSync();
  }

  final Ref _ref;
  final String taskListId;
  StreamSubscription<List<Task>>? _sub;

  void _attachStream() {
    final dao = _ref.read(taskDaoProvider);
    _sub = dao
        .watchTasksByListId(taskListId)
        .map((entries) => entries.map((e) => e.toDomain()).toList())
        .listen(
          (tasks) {
            if (!mounted) return;
            state = AsyncValue.data(tasks);
          },
          onError: (Object e, StackTrace st) {
            if (!mounted) return;
            state = AsyncValue.error(e, st);
          },
        );
  }

  /// Forces a remote sync; Drift updates flow to UI via the stream.
  Future<void> refresh() async {
    await _ref.read(taskSyncServiceProvider).syncAll();
  }

  /// Backwards-compat alias for callers that say `syncFromRemote()`.
  Future<void> syncFromRemote() => refresh();

  /// Creates a task locally and schedules a background push to Supabase.
  Future<Task> createTask(Task task) async {
    final auth = _ref.read(authNotifierProvider);
    final userId = auth is AuthAuthenticated ? auth.session.user.id : '';

    final id = task.id.isEmpty ? const Uuid().v4() : task.id;
    final next = task.copyWith(
      id: id,
      userId: userId,
      updated: DateTime.now(),
      syncStatus: SyncStatus.created,
    );

    await _ref.read(taskDaoProvider).upsertTask(next);
    _ref.read(taskSyncServiceProvider).scheduleSync();
    return next;
  }

  /// Updates a task locally and schedules a background push.
  Future<void> updateTask(Task task) async {
    final dao = _ref.read(taskDaoProvider);
    final existing = await dao.getTask(task.id);
    final next = task.copyWith(
      updated: DateTime.now(),
      syncStatus: existing?.syncStatus == SyncStatus.created.value
          ? SyncStatus.created
          : SyncStatus.updated,
    );
    await dao.upsertTask(next);
    _ref.read(taskSyncServiceProvider).scheduleSync();
  }

  /// Toggles the completion status of a task.
  Future<void> toggleComplete(Task task) async {
    final completing = !task.isCompleted;
    await updateTask(
      task.copyWith(
        status: completing ? 'completed' : 'needsAction',
        completedAt: completing ? DateTime.now() : null,
        clearCompletedAt: !completing,
      ),
    );
  }

  /// Deletes a task. If it was never pushed it's hard-deleted locally,
  /// otherwise it's marked as a tombstone for the next sync to flush.
  Future<void> deleteTask(String taskId) async {
    final dao = _ref.read(taskDaoProvider);
    final existing = await dao.getTask(taskId);
    if (existing == null) return;
    if (existing.syncStatus == SyncStatus.created.value) {
      await dao.deleteTask(taskId);
    } else {
      await dao.markDeletedLocally(taskId);
    }
    _ref.read(taskSyncServiceProvider).scheduleSync();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Family provider for [TasksNotifier]. **The** source of truth for
/// per-list task state.
final tasksNotifierProvider =
    StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>(
      (ref, taskListId) => TasksNotifier(ref: ref, taskListId: taskListId),
    );

/// Aggregates tasks across **every** task list. Used by Planned and
/// other cross-list views so they don't have to thread through every
/// list provider individually.
final allTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final listsAsync = ref.watch(taskListsNotifierProvider);

  return listsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (taskLists) {
      final aggregate = <Task>[];
      var anyLoading = false;
      Object? firstError;
      StackTrace? firstStack;

      for (final list in taskLists) {
        final tasksAsync = ref.watch(tasksNotifierProvider(list.id));
        tasksAsync.when(
          data: aggregate.addAll,
          loading: () => anyLoading = true,
          error: (e, st) {
            firstError ??= e;
            firstStack ??= st;
          },
        );
      }

      if (aggregate.isNotEmpty) {
        return AsyncValue.data(aggregate);
      }
      if (anyLoading) {
        return const AsyncValue.loading();
      }
      if (firstError != null) {
        return AsyncValue.error(firstError!, firstStack ?? StackTrace.empty);
      }
      return const AsyncValue.data(<Task>[]);
    },
  );
});
