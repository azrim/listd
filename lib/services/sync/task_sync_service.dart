import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/sync_status.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/task_dao.dart';
import '../../data/database/daos/task_list_dao.dart';
import '../atlas/mongo_realm_provider.dart';

/// Service for synchronizing local database with MongoDB Atlas via Realm.
///
/// Realm handles cloud sync automatically via Device Sync.
/// This service manages local Drift cache in sync with Realm data.
class TaskSyncService {
  TaskSyncService({
    required TaskDao taskDao,
    required TaskListDao taskListDao,
    required MongoRealmProvider realmProvider,
  }) : _taskDao = taskDao,
       _taskListDao = taskListDao,
       _realmProvider = realmProvider;

  final TaskDao _taskDao;
  final TaskListDao _taskListDao;
  final MongoRealmProvider _realmProvider;

  /// Performs a sync between local Drift cache and Realm data.
  ///
  /// Since Realm handles cloud sync automatically, this method
  /// just ensures local Drift cache stays in sync with Realm.
  ///
  /// Returns a [SyncSummary] with counts of synced items.
  Future<SyncSummary> syncAll() async {
    // Pull task lists from Realm
    final taskListSummary = await _pullTaskLists();

    // Pull tasks from Realm
    final taskSummary = await _pullTasks();

    return SyncSummary(
      taskListsUpdated: taskListSummary.updated,
      taskListsDeleted: taskListSummary.deleted,
      tasksUpdated: taskSummary.updated,
      tasksDeleted: taskSummary.deleted,
    );
  }

  /// Pulls task lists from Realm and syncs with local Drift.
  Future<_PullSummary> _pullTaskLists() async {
    try {
      // Get local task lists
      final localTaskLists = await _taskListDao.getAllTaskLists();
      final localDomainLists = localTaskLists.map((e) => e.toDomain()).toList();

      // Get Realm task lists
      final realmLists = await _realmProvider.getTaskLists();

      // Sync deleted task lists
      int deleted = 0;
      final realmIds = realmLists.map((l) => l.id).toSet();
      for (final local in localDomainLists) {
        if (!realmIds.contains(local.id) && local.syncStatus != SyncStatus.deleted) {
          await _taskListDao.deleteTaskList(local.id);
          await _taskDao.deleteTasksByListId(local.id);
          deleted++;
        }
      }

      // Upsert Realm task lists to local
      if (realmLists.isNotEmpty) {
        await _taskListDao.upsertTaskLists(realmLists);
      }

      return _PullSummary(
        updated: realmLists.length,
        deleted: deleted,
      );
    } catch (e) {
      return const _PullSummary();
    }
  }

  /// Pulls tasks from Realm and syncs with local Drift.
  Future<_PullSummary> _pullTasks() async {
    try {
      // Get all local tasks grouped by task list
      final localTasks = <String, List<Task>>{};
      final taskLists = await _taskListDao.getAllTaskLists();

      for (final taskList in taskLists) {
        final tasks = await _taskDao.getTasksByListId(taskList.id);
        localTasks[taskList.id] = tasks.map((e) => e.toDomain()).toList();
      }

      // Get Realm tasks for all task lists
      int updated = 0;
      int deleted = 0;

      for (final taskList in taskLists) {
        final realmTasks = await _realmProvider.getTasks(taskList.id);
        
        // Find deleted tasks (in local but not in Realm)
        final realmTaskIds = realmTasks.map((t) => t.id).toSet();
        for (final localTask in localTasks[taskList.id] ?? []) {
          if (!realmTaskIds.contains(localTask.id) && 
              localTask.syncStatus != SyncStatus.deleted) {
            await _taskDao.deleteTask(localTask.id);
            deleted++;
          }
        }

        // Upsert Realm tasks to local
        if (realmTasks.isNotEmpty) {
          await _taskDao.upsertTasks(realmTasks);
          updated += realmTasks.length;
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
  final app = ref.watch(realmAppProvider);

  final realmProvider = MongoRealmProvider(app);

  return TaskSyncService(
    taskDao: taskDao,
    taskListDao: taskListDao,
    realmProvider: realmProvider,
  );
});

/// Provider for sync state.
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((
  ref,
) {
  final syncService = ref.watch(taskSyncServiceProvider);
  return SyncNotifier(syncService: syncService);
});