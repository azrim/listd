import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/database/daos/task_dao.dart';
import '../../data/database/daos/task_list_dao.dart';
import '../../models/sync_status.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../tasks/supabase_tasks_provider.dart';

/// Background sync service for the local-first architecture.
///
/// The Drift database is the **source of truth** for the UI. This service
/// is responsible for:
///   1. Pushing pending local mutations (created/updated/deleted) up to
///      Supabase, then marking them synced (or hard-deleting tombstones).
///   2. Pulling the latest remote state down into Drift, taking care not
///      to clobber rows that still have unsynced local edits.
///
/// All sync work runs in the background — the UI never awaits it before
/// rendering changes. Mutations call [scheduleSync] which coalesces
/// rapid bursts into a single sync cycle.
class TaskSyncService {
  TaskSyncService({
    required TaskDao taskDao,
    required TaskListDao taskListDao,
    required SupabaseTasksProvider taskProvider,
  }) : _taskDao = taskDao,
       _taskListDao = taskListDao,
       _taskProvider = taskProvider;

  final TaskDao _taskDao;
  final TaskListDao _taskListDao;
  final SupabaseTasksProvider _taskProvider;

  /// Whether a sync cycle is currently in flight. Listenable for the
  /// status pill in the UI.
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  /// Last sync error message (null = no error). Cleared on next success.
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  /// Timestamp of the last successful sync.
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier<DateTime?>(null);

  /// Coalescing timer for [scheduleSync].
  Timer? _debounce;

  /// Performs a full sync cycle: push pending → pull remote.
  ///
  /// Safe to call concurrently — overlapping calls become no-ops.
  Future<SyncSummary> syncAll() async {
    if (isSyncing.value) return const SyncSummary();
    if (!_taskProvider.isAuthenticated) return const SyncSummary();

    isSyncing.value = true;
    try {
      final pushed = await _pushPending();
      final pulled = await _pullRemote();
      lastError.value = null;
      lastSyncedAt.value = DateTime.now();
      return SyncSummary(
        taskListsPushed: pushed.lists,
        tasksPushed: pushed.tasks,
        taskListsUpdated: pulled.taskListsUpdated,
        tasksUpdated: pulled.tasksUpdated,
      );
    } catch (e) {
      lastError.value = e.toString();
      rethrow;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Triggers a sync without awaiting the result. Coalesces rapid bursts
  /// of local mutations into a single sync cycle.
  void scheduleSync({Duration delay = const Duration(milliseconds: 250)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      // Errors are intentionally swallowed at this layer; rows stay
      // pending and will be retried on the next sync.
      unawaited(syncAll().catchError((_) => const SyncSummary()));
    });
  }

  /// Cancels any pending debounced sync. Mainly useful for tests.
  void dispose() {
    _debounce?.cancel();
    isSyncing.dispose();
    lastError.dispose();
    lastSyncedAt.dispose();
  }

  /// Push pending local mutations to Supabase, then mark synced.
  Future<_PushSummary> _pushPending() async {
    int pushedLists = 0;
    int pushedTasks = 0;

    // ── Task lists first (so any new lists exist before tasks reference them).
    final pendingLists = await _taskListDao.getPendingSyncTaskLists();
    for (final entry in pendingLists) {
      final taskList = entry.toDomain();
      try {
        switch (taskList.syncStatus) {
          case SyncStatus.created:
            await _taskProvider.createTaskList(taskList);
            await _taskListDao.markSynced(taskList.id);
            pushedLists++;
          case SyncStatus.updated:
            await _taskProvider.updateTaskList(taskList);
            await _taskListDao.markSynced(taskList.id);
            pushedLists++;
          case SyncStatus.deleted:
            await _taskProvider.deleteTaskList(taskList.id);
            // Hard delete locally too so the row stops appearing in queries.
            await _taskListDao.deleteTaskList(taskList.id);
            await _taskDao.deleteTasksByListId(taskList.id);
            pushedLists++;
          case SyncStatus.synced:
            break;
        }
      } catch (_) {
        // Leave pending; will retry next sync.
      }
    }

    // ── Tasks.
    final pendingTasks = await _taskDao.getPendingSyncTasks();
    for (final entry in pendingTasks) {
      final task = entry.toDomain();
      try {
        switch (task.syncStatus) {
          case SyncStatus.created:
            await _taskProvider.createTask(task.taskListId, task);
            await _taskDao.markSynced(task.id);
            pushedTasks++;
          case SyncStatus.updated:
            await _taskProvider.updateTask(task.taskListId, task);
            await _taskDao.markSynced(task.id);
            pushedTasks++;
          case SyncStatus.deleted:
            await _taskProvider.deleteTask(task.taskListId, task.id);
            await _taskDao.deleteTask(task.id);
            pushedTasks++;
          case SyncStatus.synced:
            break;
        }
      } catch (_) {
        // Leave pending; will retry next sync.
      }
    }

    return _PushSummary(lists: pushedLists, tasks: pushedTasks);
  }

  /// Pull remote state into Drift, preserving any rows that still have
  /// pending local edits. Skips Drift writes when the remote payload is
  /// identical to the existing local row, to avoid spurious watch-stream
  /// fires (which would cost a UI rebuild for nothing).
  Future<_PullSummary> _pullRemote() async {
    int taskListsUpdated = 0;
    int tasksUpdated = 0;

    try {
      final remoteLists = await _taskProvider.getTaskLists();
      final pendingListIds = (await _taskListDao.getPendingSyncTaskLists())
          .map((e) => e.id)
          .toSet();

      // Drop synced lists that no longer exist remotely.
      final remoteListIds = remoteLists.map((l) => l.id).toSet();
      final localLists = await _taskListDao.getAllTaskLists();
      final localListsById = {for (final l in localLists) l.id: l.toDomain()};
      for (final local in localLists) {
        if (!remoteListIds.contains(local.id) &&
            !pendingListIds.contains(local.id)) {
          await _taskListDao.deleteTaskList(local.id);
          await _taskDao.deleteTasksByListId(local.id);
        }
      }

      // Upsert remote lists, but skip rows the local user is still editing
      // *and* rows whose synced state already matches the remote payload.
      final freshLists = <TaskList>[];
      for (final remote in remoteLists) {
        if (pendingListIds.contains(remote.id)) continue;
        final local = localListsById[remote.id];
        final synced = remote.copyWith(syncStatus: SyncStatus.synced);
        if (local != null && _taskListEqual(local, synced)) continue;
        freshLists.add(synced);
      }
      if (freshLists.isNotEmpty) {
        await _taskListDao.upsertTaskLists(freshLists);
        taskListsUpdated = freshLists.length;
      }
    } catch (_) {
      return _PullSummary(
        taskListsUpdated: taskListsUpdated,
        tasksUpdated: tasksUpdated,
      );
    }

    try {
      final remoteTasks = await _taskProvider.getAllTasks();
      final pendingTaskIds = (await _taskDao.getPendingSyncTasks())
          .map((e) => e.id)
          .toSet();

      // Build a lookup of every locally-synced task once, so we don't run
      // an N+1 query per list.
      final allLists = await _taskListDao.getAllTaskLists();
      final localSyncedById = <String, Task>{};
      for (final list in allLists) {
        final entries = await _taskDao.getTasksByListId(list.id);
        for (final e in entries) {
          if (!pendingTaskIds.contains(e.id)) {
            localSyncedById[e.id] = e.toDomain();
          }
        }
      }

      // Drop synced tasks that no longer exist remotely.
      final remoteTaskIds = remoteTasks.map((t) => t.id).toSet();
      for (final id in localSyncedById.keys) {
        if (!remoteTaskIds.contains(id)) {
          await _taskDao.deleteTask(id);
        }
      }

      // Upsert remote tasks, skipping any with pending local edits AND any
      // that already match the local synced row.
      final freshTasks = <Task>[];
      for (final remote in remoteTasks) {
        if (pendingTaskIds.contains(remote.id)) continue;
        final local = localSyncedById[remote.id];
        final synced = remote.copyWith(syncStatus: SyncStatus.synced);
        if (local != null && _taskEqual(local, synced)) continue;
        freshTasks.add(synced);
      }
      if (freshTasks.isNotEmpty) {
        await _taskDao.upsertTasks(freshTasks);
        tasksUpdated = freshTasks.length;
      }
    } catch (_) {
      // Network/server failure — leave Drift as-is.
    }

    return _PullSummary(
      taskListsUpdated: taskListsUpdated,
      tasksUpdated: tasksUpdated,
    );
  }

  static bool _taskListEqual(TaskList a, TaskList b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.isDefault == b.isDefault &&
        a.position == b.position &&
        a.userId == b.userId &&
        a.syncStatus == b.syncStatus;
  }

  static bool _taskEqual(Task a, Task b) {
    // Reuse the Task `==` operator (already covers every field).
    return a == b;
  }

  /// Performs a full sync.
  Future<SyncSummary> fullSync() => syncAll();
}

/// Summary of a sync operation.
class SyncSummary {
  const SyncSummary({
    this.taskListsUpdated = 0,
    this.tasksUpdated = 0,
    this.taskListsPushed = 0,
    this.tasksPushed = 0,
  });

  final int taskListsUpdated;
  final int tasksUpdated;
  final int taskListsPushed;
  final int tasksPushed;

  @override
  String toString() {
    return 'SyncSummary(pushed: lists=$taskListsPushed/tasks=$tasksPushed, '
        'pulled: lists=$taskListsUpdated/tasks=$tasksUpdated)';
  }
}

class _PushSummary {
  const _PushSummary({this.lists = 0, this.tasks = 0});
  final int lists;
  final int tasks;
}

class _PullSummary {
  const _PullSummary({this.taskListsUpdated = 0, this.tasksUpdated = 0});
  final int taskListsUpdated;
  final int tasksUpdated;
}

/// Riverpod-side accessors are wired up in `providers/sync_provider.dart`.
TaskSyncService taskSyncServiceFromRefs({
  required TaskDao taskDao,
  required TaskListDao taskListDao,
  required SupabaseTasksProvider taskProvider,
}) {
  return TaskSyncService(
    taskDao: taskDao,
    taskListDao: taskListDao,
    taskProvider: taskProvider,
  );
}
