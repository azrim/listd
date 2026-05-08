import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/task_lists_table.dart';
import '../../../models/task_list.dart' as domain;
import '../../../models/sync_status.dart';

part 'task_list_dao.g.dart';

/// Data Access Object for task list operations.
///
/// Provides CRUD operations and sync-related queries for task lists.
@DriftAccessor(tables: [TaskLists])
class TaskListDao extends DatabaseAccessor<AppDatabase>
    with _$TaskListDaoMixin {
  TaskListDao(super.db);

  /// Watches all task lists not pending deletion, ordered by position
  /// then title (matches sidebar order).
  Stream<List<TaskListEntry>> watchAllTaskLists() {
    return (select(taskLists)
          ..where((t) => t.syncStatus.isSmallerThanValue(3))
          ..orderBy([
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.title),
          ]))
        .watch();
  }

  /// Gets all task lists (excluding pending deletes).
  Future<List<TaskListEntry>> getAllTaskLists() {
    return (select(taskLists)
          ..where((t) => t.syncStatus.isSmallerThanValue(3))
          ..orderBy([
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.title),
          ]))
        .get();
  }

  /// Gets a single task list by ID.
  Future<TaskListEntry?> getTaskList(String id) {
    return (select(taskLists)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Gets the default task list.
  Future<TaskListEntry?> getDefaultTaskList() {
    return (select(taskLists)..where(
          (t) => t.isDefault.equals(true) & t.syncStatus.isSmallerThanValue(3),
        ))
        .getSingleOrNull();
  }

  /// Inserts or updates a task list.
  Future<void> upsertTaskList(domain.TaskList taskList) {
    return into(taskLists).insertOnConflictUpdate(_toCompanion(taskList));
  }

  /// Inserts or updates multiple task lists.
  Future<void> upsertTaskLists(List<domain.TaskList> list) async {
    if (list.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        taskLists,
        list.map(_toCompanion).toList(),
      );
    });
  }

  /// Marks a task list as deleted locally (sets sync status to deleted).
  Future<void> markDeletedLocally(String id) {
    return (update(taskLists)..where((t) => t.id.equals(id))).write(
      const TaskListsCompanion(syncStatus: Value(3)),
    );
  }

  /// Marks a task list with the given sync status (used to flag local edits).
  Future<void> markSyncStatus(String id, SyncStatus status) {
    return (update(taskLists)..where((t) => t.id.equals(id))).write(
      TaskListsCompanion(syncStatus: Value(status.value)),
    );
  }

  /// Hard deletes a task list from the database.
  Future<void> deleteTaskList(String id) {
    return (delete(taskLists)..where((t) => t.id.equals(id))).go();
  }

  /// Gets all task lists with pending sync changes.
  Future<List<TaskListEntry>> getPendingSyncTaskLists() {
    return (select(
      taskLists,
    )..where((t) => t.syncStatus.isBiggerOrEqualValue(1))).get();
  }

  /// Streams the count of task lists with pending sync changes.
  Stream<int> watchPendingSyncCount() {
    final query = selectOnly(taskLists)
      ..addColumns([taskLists.id.count()])
      ..where(taskLists.syncStatus.isBiggerOrEqualValue(1));
    return query
        .map((row) => row.read(taskLists.id.count()) ?? 0)
        .watchSingle();
  }

  /// Gets all task lists with specific sync status.
  Future<List<TaskListEntry>> getTaskListsBySyncStatus(SyncStatus status) {
    return (select(
      taskLists,
    )..where((t) => t.syncStatus.equals(status.value))).get();
  }

  /// Marks a task list as synced (resets sync status to 0).
  Future<void> markSynced(String id) {
    return (update(taskLists)..where((t) => t.id.equals(id))).write(
      const TaskListsCompanion(syncStatus: Value(0)),
    );
  }

  /// Marks multiple task lists as synced.
  Future<void> markSyncedBatch(List<String> ids) async {
    await batch((batch) {
      batch.update(
        taskLists,
        const TaskListsCompanion(syncStatus: Value(0)),
        where: (t) => t.id.isIn(ids),
      );
    });
  }

  /// Clears the default flag from all task lists.
  Future<void> clearAllDefaults() async {
    await (update(taskLists)..where((t) => t.isDefault.equals(true))).write(
      const TaskListsCompanion(isDefault: Value(false)),
    );
  }

  /// Sets a task list as the default.
  Future<void> setDefault(String id) async {
    await clearAllDefaults();
    await (update(taskLists)..where((t) => t.id.equals(id))).write(
      const TaskListsCompanion(isDefault: Value(true)),
    );
  }

  TaskListsCompanion _toCompanion(domain.TaskList taskList) {
    return TaskListsCompanion(
      id: Value(taskList.id),
      title: Value(taskList.title),
      updated: Value(taskList.updated.toIso8601String()),
      syncStatus: Value(taskList.syncStatus.value),
      isDefault: Value(taskList.isDefault),
      userId: Value(taskList.userId),
      position: Value(taskList.position),
    );
  }
}

/// Extension to convert TaskListEntry to domain model
extension TaskListEntryExtension on TaskListEntry {
  /// Converts database entry to domain model
  domain.TaskList toDomain() {
    return domain.TaskList(
      id: id,
      title: title,
      updated: DateTime.parse(updated),
      syncStatus: SyncStatus.fromValue(syncStatus),
      isDefault: isDefault,
      userId: userId,
      position: position,
    );
  }
}
