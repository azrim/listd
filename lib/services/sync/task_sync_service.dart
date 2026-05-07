import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/sync_status.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/task_dao.dart';
import '../../data/database/daos/task_list_dao.dart';
import '../../providers/task_lists_provider.dart'
    show supabaseTasksProviderProvider;
import '../tasks/supabase_tasks_provider.dart';

/// Service for synchronizing local Drift cache with Supabase.
///
/// This service manages local Drift cache in sync with Supabase data.
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

  /// Performs a sync between local Drift cache and Supabase data.
  ///
  /// Returns a [SyncSummary] with counts of synced items.
  Future<SyncSummary> syncAll() async {
    // Pull task lists from Supabase
    final taskListSummary = await _pullTaskLists();

    // Pull tasks from Supabase
    final taskSummary = await _pullTasks();

    return SyncSummary(
      taskListsUpdated: taskListSummary.updated,
      taskListsDeleted: taskListSummary.deleted,
      tasksUpdated: taskSummary.updated,
      tasksDeleted: taskSummary.deleted,
    );
  }

  /// Pulls task lists from Supabase and syncs with local Drift.
  Future<_PullSummary> _pullTaskLists() async {
    try {
      // Get local task lists
      final localTaskLists = await _taskListDao.getAllTaskLists();
      final localDomainLists = localTaskLists.map((e) => e.toDomain()).toList();

      // Get Supabase task lists
      final remoteLists = await _taskProvider.getTaskLists();

      // Sync deleted task lists
      int deleted = 0;
      final remoteIds = remoteLists.map((l) => l.id).toSet();
      for (final local in localDomainLists) {
        if (!remoteIds.contains(local.id) &&
            local.syncStatus != SyncStatus.deleted) {
          await _taskListDao.deleteTaskList(local.id);
          await _taskDao.deleteTasksByListId(local.id);
          deleted++;
        }
      }

      // Upsert remote task lists to local
      if (remoteLists.isNotEmpty) {
        await _taskListDao.upsertTaskLists(remoteLists);
      }

      return _PullSummary(updated: remoteLists.length, deleted: deleted);
    } catch (e) {
      return const _PullSummary();
    }
  }

  /// Pulls tasks from Supabase and syncs with local Drift.
  Future<_PullSummary> _pullTasks() async {
    try {
      // Get all local tasks grouped by task list
      final localTasks = <String, List<Task>>{};
      final taskLists = await _taskListDao.getAllTaskLists();

      for (final taskList in taskLists) {
        final tasks = await _taskDao.getTasksByListId(taskList.id);
        localTasks[taskList.id] = tasks.map((e) => e.toDomain()).toList();
      }

      // Get remote tasks for all task lists
      int updated = 0;
      int deleted = 0;

      for (final taskList in taskLists) {
        final remoteTasks = await _taskProvider.getTasks(taskList.id);

        // Find deleted tasks (in local but not in remote)
        final remoteTaskIds = remoteTasks.map((t) => t.id).toSet();
        for (final localTask in localTasks[taskList.id] ?? []) {
          if (!remoteTaskIds.contains(localTask.id) &&
              localTask.syncStatus != SyncStatus.deleted) {
            await _taskDao.deleteTask(localTask.id);
            deleted++;
          }
        }

        // Upsert remote tasks to local
        if (remoteTasks.isNotEmpty) {
          await _taskDao.upsertTasks(remoteTasks);
          updated += remoteTasks.length;
        }
      }

      return _PullSummary(updated: updated, deleted: deleted);
    } catch (e) {
      return const _PullSummary();
    }
  }

  /// Performs a full sync.
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
final taskDaoProviderSync = Provider<TaskDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskDao(db);
});

/// Provider for TaskListDao.
final taskListDaoProviderSync = Provider<TaskListDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskListDao(db);
});

/// Provider for TaskSyncService.
final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  final taskDao = ref.watch(taskDaoProviderSync);
  final taskListDao = ref.watch(taskListDaoProviderSync);

  // Import from providers
  final supabaseTasksProvider = ref.watch(supabaseTasksProviderProvider);

  return TaskSyncService(
    taskDao: taskDao,
    taskListDao: taskListDao,
    taskProvider: supabaseTasksProvider,
  );
});

/// Provider for sync state.
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((
  ref,
) {
  final syncService = ref.watch(taskSyncServiceProvider);
  return SyncNotifier(syncService: syncService);
});
