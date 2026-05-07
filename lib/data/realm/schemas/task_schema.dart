import 'package:realm/realm.dart';

part 'task_schema.realm.dart';

/// Realm schema for a task.
@RealmModel()
class _TaskSchema {
  @PrimaryKey()
  late ObjectId id;

  late String title;
  late String notes;

  DateTime? due;

  late bool isCompleted;
  late bool isImportant;
  late bool isMyDay;

  /// The task list ID this task belongs to.
  late String taskListId;

  /// Parent task ID (for subtasks).
  late String parentId;

  /// Position in the task list (for ordering).
  late int position;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Whether this task was deleted locally (soft delete).
  late bool isDeleted;
}