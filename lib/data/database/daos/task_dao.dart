import 'dart:convert';

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

  /// Watches all tasks not pending deletion, ordered by position.
  Stream<List<TaskEntry>> watchAllTasks() {
    return (select(tasks)
          ..where((t) => t.syncStatus.isSmallerThanValue(3))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Watches tasks (excluding pending deletes) filtered by task list ID.
  Stream<List<TaskEntry>> watchTasksByListId(String taskListId) {
    return (select(tasks)
          ..where(
            (t) =>
                t.taskListId.equals(taskListId) &
                t.syncStatus.isSmallerThanValue(3),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Gets all tasks for a task list (excluding pending deletes).
  Future<List<TaskEntry>> getTasksByListId(String taskListId) {
    return (select(tasks)
          ..where(
            (t) =>
                t.taskListId.equals(taskListId) &
                t.syncStatus.isSmallerThanValue(3),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  /// Gets a single task by ID.
  Future<TaskEntry?> getTask(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Inserts or updates a task. Callers should set [task.syncStatus] to
  /// `created`/`updated`/`deleted` for local mutations, or `synced` for
  /// rows pulled from Supabase.
  Future<void> upsertTask(domain.Task task) {
    return into(tasks).insertOnConflictUpdate(_toCompanion(task));
  }

  /// Inserts or updates multiple tasks.
  Future<void> upsertTasks(List<domain.Task> taskList) async {
    if (taskList.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        tasks,
        taskList.map(_toCompanion).toList(),
      );
    });
  }

  /// Marks a task as deleted locally so background sync can push the
  /// deletion to Supabase. The row is kept until the push succeeds.
  Future<void> markDeletedLocally(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      const TasksCompanion(syncStatus: Value(3)),
    );
  }

  /// Marks a task with the given sync status (used to flag local edits).
  Future<void> markSyncStatus(String id, SyncStatus status) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(syncStatus: Value(status.value)),
    );
  }

  /// Hard deletes a task from the database (used after a successful
  /// remote-side delete, or when a row was never synced).
  Future<void> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Gets all tasks with pending sync changes (created/updated/deleted).
  Future<List<TaskEntry>> getPendingSyncTasks() {
    return (select(
      tasks,
    )..where((t) => t.syncStatus.isBiggerOrEqualValue(1))).get();
  }

  /// Streams the count of tasks with pending sync changes
  /// (created/updated/deleted). Used by the sync status pill.
  Stream<int> watchPendingSyncCount() {
    final query = selectOnly(tasks)
      ..addColumns([tasks.id.count()])
      ..where(tasks.syncStatus.isBiggerOrEqualValue(1));
    return query.map((row) => row.read(tasks.id.count()) ?? 0).watchSingle();
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
      const TasksCompanion(syncStatus: Value(0)),
    );
  }

  /// Marks multiple tasks as synced.
  Future<void> markSyncedBatch(List<String> ids) async {
    await batch((batch) {
      batch.update(
        tasks,
        const TasksCompanion(syncStatus: Value(0)),
        where: (t) => t.id.isIn(ids),
      );
    });
  }

  /// Deletes all tasks for a task list.
  Future<void> deleteTasksByListId(String taskListId) {
    return (delete(tasks)..where((t) => t.taskListId.equals(taskListId))).go();
  }

  TasksCompanion _toCompanion(domain.Task task) {
    return TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      notes: Value(task.notes),
      due: Value(task.due?.toIso8601String()),
      status: Value(task.status),
      updated: Value(task.updated.toIso8601String()),
      taskListId: Value(task.taskListId),
      parentId: Value(task.parentId),
      position: Value(task.position),
      manuallyAddedToToday: Value(task.manuallyAddedToToday),
      isStarred: Value(task.isStarred),
      reminder: Value(task.reminder?.toIso8601String()),
      repeatConfig: Value(
        task.repeat == null ? null : jsonEncode(task.repeat!.toJson()),
      ),
      tags: Value(task.tags.isEmpty ? null : jsonEncode(task.tags)),
      steps: Value(
        task.steps.isEmpty
            ? null
            : jsonEncode(task.steps.map((s) => s.toJson()).toList()),
      ),
      completedAt: Value(task.completedAt?.toIso8601String()),
      userId: Value(task.userId),
      syncStatus: Value(task.syncStatus.value),
    );
  }
}

/// Extension to convert TaskEntry to domain model
extension TaskEntryExtension on TaskEntry {
  /// Converts database entry to domain model
  domain.Task toDomain() {
    domain.RepeatConfig? repeat;
    if (repeatConfig != null) {
      try {
        final json = jsonDecode(repeatConfig!) as Map<String, dynamic>;
        repeat = domain.RepeatConfig.fromJson(json);
      } catch (_) {
        repeat = null;
      }
    }

    final List<String> parsedTags = () {
      if (tags == null) return const <String>[];
      try {
        final decoded = jsonDecode(tags!);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return const <String>[];
    }();

    final List<domain.TaskStep> parsedSteps = () {
      if (steps == null) return const <domain.TaskStep>[];
      try {
        final decoded = jsonDecode(steps!);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (e) => domain.TaskStep.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        }
      } catch (_) {}
      return const <domain.TaskStep>[];
    }();

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
      manuallyAddedToToday: manuallyAddedToToday,
      isStarred: isStarred,
      reminder: reminder != null ? DateTime.parse(reminder!) : null,
      repeat: repeat,
      tags: parsedTags,
      steps: parsedSteps,
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
      userId: userId,
      syncStatus: SyncStatus.fromValue(syncStatus),
    );
  }
}
