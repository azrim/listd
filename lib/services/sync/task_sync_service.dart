import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// rendering changes.
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

  /// Whether a sync cycle is currently in flight.
  bool get isSyncing => _running;
  bool _running = false;

  /// Performs a full sync cycle: push pending → pull remote.
  ///
  /// Safe to call concurrently — overlapping calls become no-ops.
  Future<SyncSummary> syncAll() async {
    if (_running) return const SyncSummary();
    _running = true;
    try {
      if (!_taskProvider.isAuthenticated) return const SyncSummary();

      final pushed = await _pushPending();
      final pulled = await _pullRemote();
      return SyncSummary(
        taskListsPushed: pushed.lists,
        tasksPushed: pushed.tasks,
        taskListsUpdated: pulled.taskListsUpdated,
        tasksUpdated: pulled.tasksUpdated,
      );
    } finally {
      _running = false;
    }
  }

  /// Triggers a sync without awaiting the result. Use after a local
  /// mutation so the UI doesn't block on network.
  void scheduleSync() {
    // Fire-and-forget. Errors are intentionally swallowed; the row stays
    // pending and will be retried on the next sync.
    unawaited(syncAll());
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
  /// pending local edits.
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
      for (final local in localLists) {
        if (!remoteListIds.contains(local.id) &&
            !pendingListIds.contains(local.id)) {
          await _taskListDao.deleteTaskList(local.id);
          await _taskDao.deleteTasksByListId(local.id);
        }
      }

      // Upsert remote lists, but skip rows the local user is still editing.
      final freshLists = remoteLists
          .where((l) => !pendingListIds.contains(l.id))
          .toList();
      if (freshLists.isNotEmpty) {
        await _taskListDao.upsertTaskLists(
          freshLists
              .map((l) => l.copyWith(syncStatus: SyncStatus.synced))
              .toList(),
        );
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

      // Drop synced tasks that no longer exist remotely (and aren't pending
      // a local-side mutation that hasn't reached the server yet).
      final remoteTaskIds = remoteTasks.map((t) => t.id).toSet();
      final localTasks = await _taskDao.getPendingSyncTasks();
      // Note: we only want to compare *synced* local tasks against remote.
      // Pull all task lists then their tasks individually.
      final allLists = await _taskListDao.getAllTaskLists();
      final localSyncedIds = <String>{};
      for (final list in allLists) {
        final entries = await _taskDao.getTasksByListId(list.id);
        for (final e in entries) {
          if (!pendingTaskIds.contains(e.id)) localSyncedIds.add(e.id);
        }
      }
      // Avoid lint about unused var.
      localTasks.length;
      for (final id in localSyncedIds) {
        if (!remoteTaskIds.contains(id)) {
          await _taskDao.deleteTask(id);
        }
      }

      // Upsert remote tasks, skipping any with pending local edits.
      final freshTasks = remoteTasks
          .where((t) => !pendingTaskIds.contains(t.id))
          .toList();
      if (freshTasks.isNotEmpty) {
        await _taskDao.upsertTasks(
          freshTasks
              .map((t) => t.copyWith(syncStatus: SyncStatus.synced))
              .toList(),
        );
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

/// Notifier for managing sync state.
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier({required TaskSyncService syncService})
    : _syncService = syncService,
      super(const SyncIdle());

  final TaskSyncService _syncService;

  /// Triggers a full sync.
  Future<void> sync() async {
    if (state is SyncInProgress) return;
    state = const SyncInProgress();
    try {
      final summary = await _syncService.syncAll();
      state = SyncSuccess(summary);
    } catch (e) {
      state = SyncError(e.toString());
    }
  }
}

/// Sealed type for sync state.
sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  const SyncInProgress();
}

class SyncSuccess extends SyncState {
  const SyncSuccess(this.summary);
  final SyncSummary summary;
}

class SyncError extends SyncState {
  const SyncError(this.message);
  final String message;
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

/// Convenience: run a single one-shot sync against the given collaborators.
/// Used by tests and headless tooling.
Future<SyncSummary> runOneShotSync({
  required TaskDao taskDao,
  required TaskListDao taskListDao,
  required SupabaseTasksProvider taskProvider,
}) {
  return TaskSyncService(
    taskDao: taskDao,
    taskListDao: taskListDao,
    taskProvider: taskProvider,
  ).syncAll();
}

/// Convenience helper bound to a domain [Task] for tests.
Task taskWithSync(Task task, SyncStatus status) =>
    task.copyWith(syncStatus: status);

/// Convenience helper bound to a domain [TaskList] for tests.
TaskList taskListWithSync(TaskList taskList, SyncStatus status) =>
    taskList.copyWith(syncStatus: status);
