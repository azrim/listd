import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tasks_table.dart';
import '../../../models/task.dart' as domain;
import '../../../models/sync_status.dart';

part 'task_dao.g.dart';

/// Data Access Object for task operations.
///
/// Provides CRUD operations and sync-related queries for tasks.
@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watches all tasks, ordered by position.
  Stream<List<TaskEntry>> watchAllTasks() {
    return (select(
      tasks,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).watch();
  }

  /// Watches tasks filtered by task list ID.
  Stream<List<TaskEntry>> watchTasksByListId(String taskListId) {
    return (select(tasks)
          ..where((t) => t.taskListId.equals(taskListId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Gets all tasks for a task list.
  Future<List<TaskEntry>> getTasksByListId(String taskListId) {
    return (select(tasks)
          ..where((t) => t.taskListId.equals(taskListId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  /// Gets a single task by ID.
  Future<TaskEntry?> getTask(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Inserts or updates a task.
  Future<void> upsertTask(domain.Task task) {
    return into(tasks).insertOnConflictUpdate(
      TaskEntry(
        id: task.id,
        title: task.title,
        notes: task.notes,
        due: task.due?.toIso8601String(),
        status: task.status,
        updated: task.updated.toIso8601String(),
        taskListId: task.taskListId,
        parentId: task.parentId,
        position: task.position,
        syncStatus: task.syncStatus.value,
      ),
    );
  }

  /// Inserts or updates multiple tasks.
  Future<void> upsertTasks(List<domain.Task> taskList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        tasks,
        taskList
            .map(
              (t) => TaskEntry(
                id: t.id,
                title: t.title,
                notes: t.notes,
                due: t.due?.toIso8601String(),
                status: t.status,
                updated: t.updated.toIso8601String(),
                taskListId: t.taskListId,
                parentId: t.parentId,
                position: t.position,
                syncStatus: t.syncStatus.value,
              ),
            )
            .toList(),
      );
    });
  }

  /// Marks a task as deleted locally (sets sync status to deleted).
  Future<void> markDeletedLocally(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(syncStatus: const Value(3)),
    );
  }

  /// Hard deletes a task from the database.
  Future<void> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Gets all tasks with pending sync changes.
  Future<List<TaskEntry>> getPendingSyncTasks() {
    return (select(
      tasks,
    )..where((t) => t.syncStatus.isBiggerOrEqualValue(1))).get();
  }

  /// Gets all tasks with specific sync status.
  Future<List<TaskEntry>> getTasksBySyncStatus(SyncStatus status) {
    return (select(
      tasks,
    )..where((t) => t.syncStatus.equals(status.value))).get();
  }

  /// Marks a task as synced (resets sync status to 0).
  Future<void> markSynced(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(syncStatus: const Value(0)),
    );
  }

  /// Marks multiple tasks as synced.
  Future<void> markSyncedBatch(List<String> ids) async {
    await batch((batch) {
      batch.update(
        tasks,
        TasksCompanion(syncStatus: const Value(0)),
        where: (t) => t.id.isIn(ids),
      );
    });
  }

  /// Deletes all tasks for a task list.
  Future<void> deleteTasksByListId(String taskListId) {
    return (delete(tasks)..where((t) => t.taskListId.equals(taskListId))).go();
  }
}

/// Extension to convert TaskEntry to domain model
extension TaskEntryExtension on TaskEntry {
  /// Converts database entry to domain model
  domain.Task toDomain() {
    return domain.Task(
      id: id,
      title: title,
      notes: notes,
      due: due != null ? DateTime.parse(due!) : null,
      status: status,
      updated: DateTime.parse(updated),
      taskListId: taskListId,
      parentId: parentId,
      position: position,
      syncStatus: SyncStatus.fromValue(syncStatus),
    );
  }
}
