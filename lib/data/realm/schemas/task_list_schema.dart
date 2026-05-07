import 'package:realm/realm.dart';

part 'task_list_schema.realm.dart';

/// Realm schema for a task list.
@RealmModel()
class _TaskListSchema {
  @PrimaryKey()
  late ObjectId id;

  late String title;

  /// Whether this is the user's default task list.
  late bool isDefault;

  /// Position in the sidebar (for ordering).
  late int position;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Whether this task list was deleted locally (soft delete).
  late bool isDeleted;
}