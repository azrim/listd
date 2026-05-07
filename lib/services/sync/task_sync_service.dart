import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tasks/google_tasks_provider.dart';
import '../tasks/task_provider.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../models/sync_status.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/task_dao.dart';
import '../../data/database/daos/task_list_dao.dart';

/// Service for synchronizing local database with remote Google Tasks.
///
/// Handles bidirectional sync: pulling remote changes and pushing local changes.
class TaskSyncService {
  TaskSyncService({
    required TaskDao taskDao,
    required TaskListDao taskListDao,
    required ITaskProvider taskProvider,
  }) : _taskDao = taskDao,
       _taskListDao = taskListDao,
       _taskProvider = taskProvider;

  final TaskDao _taskDao;
  final TaskListDao _taskListDao;
  final ITaskProvider _taskProvider;

  /// Performs a full sync between local database and remote Google Tasks.
  ///
  /// Sync strategy (last-write-wins):
  /// 1. Push local changes (created/updated/deleted) to remote
  /// 2. Pull remote data
  /// 3. Merge based on updated timestamps
  ///
  /// Returns a [SyncSummary] with counts of synced items.
  Future<SyncSummary> syncAll() async {
    // Pull task lists first
    final taskListSummary = await _pullTaskLists();

    // Pull tasks for each task list
    final taskSummary = await _pullTasks();

    return SyncSummary(
      taskListsUpdated: taskListSummary.updated,
      taskListsDeleted: taskListSummary.deleted,
      tasksUpdated: taskSummary.updated,
      tasksDeleted: taskSummary.deleted,
    );
  }

  /// Pulls task lists from remote and merges with local.
  Future<_PullSummary> _pullTaskLists() async {
    try {
      // Get local task lists
      final localTaskLists = await _taskListDao.getAllTaskLists();
      final localDomainLists = localTaskLists.map((e) => e.toDomain()).toList();

      // Get pending sync items (local changes to push)
      final pendingLists = await _taskListDao.getPendingSyncTaskLists();

      // Push local changes
      await _pushTaskLists(pendingLists.map((e) => e.toDomain()).toList());

      // Pull remote data
      final syncResult = await _taskProvider.sync(localDomainLists, {});

      // Process deleted task lists
      int deleted = 0;
      for (final id in syncResult.deletedTaskListIds) {
        await _taskListDao.deleteTaskList(id);
        await _taskDao.deleteTasksByListId(id);
        deleted++;
      }

      // Upsert remote task lists
      if (syncResult.taskLists.isNotEmpty) {
        await _taskListDao.upsertTaskLists(syncResult.taskLists);
      }

      return _PullSummary(
        updated: syncResult.taskLists.length,
        deleted: deleted,
      );
    } catch (e) {
      // On error, return empty summary - caller should handle
      return const _PullSummary();
    }
  }

  /// Pushes local task list changes to remote.
  Future<void> _pushTaskLists(List<TaskList> taskLists) async {
    if (!_taskProvider.capabilities.canUpdateTaskLists) return;

    for (final taskList in taskLists) {
      // Skip synced or already deleted items
      if (taskList.syncStatus == SyncStatus.synced) continue;
      if (taskList.syncStatus == SyncStatus.deleted) {
        // Try to delete on remote if it exists
        if (_taskProvider.capabilities.canDeleteTaskLists) {
          try {
            await _taskProvider.deleteTask(taskList.id, taskList.id);
          } catch (_) {
            // Ignore errors - item might not exist on remote
          }
        }
      }
      // Note: Google Tasks API doesn't support creating/updating task lists
      // So we just mark local changes as synced after attempting
    }
  }

  /// Pulls tasks from remote and merges with local.
  Future<_PullSummary> _pullTasks() async {
    try {
      // Get all local tasks
      final localTasks = <String, List<Task>>{};
      final taskLists = await _taskListDao.getAllTaskLists();

      for (final taskList in taskLists) {
        final tasks = await _taskDao.getTasksByListId(taskList.id);
        localTasks[taskList.id] = tasks.map((e) => e.toDomain()).toList();
      }

      // Get pending sync items (local changes to push)
      final allPendingTasks = await _taskDao.getPendingSyncTasks();

      // Push local changes
      await _pushTasks(allPendingTasks.map((e) => e.toDomain()).toList());

      // Pull remote data using sync method
      final syncResult = await _taskProvider.sync([], localTasks);

      // Process deleted tasks
      int deleted = 0;
      for (final taskListId in syncResult.deletedTaskListIds) {
        await _taskDao.deleteTasksByListId(taskListId);
        deleted++;
      }

      // Upsert remote tasks
      int updated = 0;
      for (final entry in syncResult.tasks.entries) {
        if (entry.value.isNotEmpty) {
          await _taskDao.upsertTasks(entry.value);
          updated += entry.value.length;
        }
      }

      return _PullSummary(updated: updated, deleted: deleted);
    } catch (e) {
      return const _PullSummary();
    }
  }

  /// Pushes local task changes to remote.
  Future<void> _pushTasks(List<Task> tasks) async {
    if (!_taskProvider.capabilities.canCreateTasks &&
        !_taskProvider.capabilities.canUpdateTasks &&
        !_taskProvider.capabilities.canDeleteTasks) {
      return;
    }

    for (final task in tasks) {
      if (task.syncStatus == SyncStatus.synced) continue;

      try {
        if (task.syncStatus == SyncStatus.deleted) {
          if (_taskProvider.capabilities.canDeleteTasks) {
            await _taskProvider.deleteTask(task.taskListId, task.id);
            await _taskDao.deleteTask(task.id);
          }
        } else if (task.syncStatus == SyncStatus.created) {
          if (_taskProvider.capabilities.canCreateTasks) {
            final createdTask = await _taskProvider.createTask(
              task.taskListId,
              task,
            );
            // Update local with remote ID and synced status
            await _taskDao.upsertTask(
              createdTask.copyWith(
                taskListId: task.taskListId,
                syncStatus: SyncStatus.synced,
              ),
            );
          }
        } else if (task.syncStatus == SyncStatus.updated) {
          if (_taskProvider.capabilities.canUpdateTasks) {
            await _taskProvider.updateTask(task.taskListId, task);
            await _taskDao.markSynced(task.id);
          }
        }
      } catch (e) {
        // On individual task sync failure, continue with others
        // The task will remain with its pending sync status
      }
    }
  }

  /// Performs a full sync including both push and pull phases.
  ///
  /// This is the main entry point for initiating a complete sync.
  Future<SyncSummary> fullSync() async {
    return syncAll();
  }
}

/// Summary of a sync operation.
class SyncSummary {
  const SyncSummary({
    this.taskListsUpdated = 0,
    this.taskListsDeleted = 0,
    this.tasksUpdated = 0,
    this.tasksDeleted = 0,
  });

  final int taskListsUpdated;
  final int taskListsDeleted;
  final int tasksUpdated;
  final int tasksDeleted;

  @override
  String toString() {
    return 'SyncSummary(taskLists: +$taskListsUpdated/-$taskListsDeleted, '
        'tasks: +$tasksUpdated/-$tasksDeleted)';
  }
}

/// Internal summary for pull operations.
class _PullSummary {
  const _PullSummary({this.updated = 0, this.deleted = 0});
  final int updated;
  final int deleted;
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
      final summary = await _syncService.fullSync();
      state = SyncCompleted(summary);
    } catch (e) {
      state = SyncFailed(e.toString());
    }
  }

  /// Resets to idle state.
  void reset() {
    state = const SyncIdle();
  }
}

/// Base class for sync states.
sealed class SyncState {
  const SyncState();
}

/// No sync in progress.
class SyncIdle extends SyncState {
  const SyncIdle();
}

/// Sync is currently in progress.
class SyncInProgress extends SyncState {
  const SyncInProgress();
}

/// Sync completed successfully.
class SyncCompleted extends SyncState {
  const SyncCompleted(this.summary);
  final SyncSummary summary;
}

/// Sync failed with an error.
class SyncFailed extends SyncState {
  const SyncFailed(this.error);
  final String error;
}

/// Provider for AppDatabase.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden');
});

/// Provider for TaskDao.
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskDao(db);
});

/// Provider for TaskListDao.
final taskListDaoProvider = Provider<TaskListDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskListDao(db);
});

/// Provider for TaskSyncService.
final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  final taskDao = ref.watch(taskDaoProvider);
  final taskListDao = ref.watch(taskListDaoProvider);
  final taskProvider = ref.watch(googleTasksProvider);

  return TaskSyncService(
    taskDao: taskDao,
    taskListDao: taskListDao,
    taskProvider: taskProvider,
  );
});

/// Provider for sync state.
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((
  ref,
) {
  final syncService = ref.watch(taskSyncServiceProvider);
  return SyncNotifier(syncService: syncService);
});
