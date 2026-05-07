import 'package:drift/drift.dart';

/// Drift table definition for tasks.
///
/// This table stores task entities with all their attributes including
/// sync status for tracking changes that need to be pushed to Google Tasks API.
@DataClassName('TaskEntry')
class Tasks extends Table {
  /// Unique identifier (Google Tasks API format)
  TextColumn get id => text()();

  /// Task title/text
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Additional notes or description
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Due date as ISO8601 string (null if no due date)
  TextColumn get due => text().nullable()();

  /// Completion status: 'needsAction' or 'completed'
  TextColumn get status => text().withDefault(const Constant('needsAction'))();

  /// Last update timestamp as ISO8601 string
  TextColumn get updated => text()();

  /// Parent task list ID this task belongs to
  TextColumn get taskListId => text()();

  /// Parent task ID for subtasks (null for top-level tasks)
  TextColumn get parentId => text().nullable()();

  /// Position within the task list for ordering
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Whether this task is starred/favorited
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();

  /// Sync status: 0=synced, 1=created, 2=updated, 3=deleted
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
