import 'package:drift/drift.dart';

/// Drift table definition for tasks.
///
/// This table is the **local-first source of truth** for tasks. The full
/// task domain model is mirrored here so the UI can render and mutate
/// tasks entirely against Drift, without waiting on Supabase.
///
/// `syncStatus` records whether each row is `synced`, `created`,
/// `updated`, or `deleted`. Background sync drains pending rows into
/// Supabase and reconciles remote changes back into this table.
@DataClassName('TaskEntry')
class Tasks extends Table {
  /// Unique identifier
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

  /// Position within the task list for ordering.
  /// Uses a real (double) to support fractional insertion:
  /// inserting between positions 1024 and 2048 → 1536.
  RealColumn get position => real().withDefault(const Constant(0))();

  /// Whether this task was manually added to the Today smart bucket.
  /// Default false — only true when the user explicitly drags/adds a
  /// task to Today that wouldn't otherwise appear there.
  BoolColumn get manuallyAddedToToday =>
      boolean().withDefault(const Constant(false))();

  /// Whether this task is starred/favorited
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();

  /// Reminder timestamp as ISO8601 string (null if no reminder)
  TextColumn get reminder => text().nullable()();

  /// Repeat configuration as JSON string (null if not repeating)
  TextColumn get repeatConfig => text().nullable()();

  /// Tags encoded as a JSON array string (null/[] if no tags)
  TextColumn get tags => text().nullable()();

  /// Steps/subtasks encoded as a JSON array string (null/[] if no steps)
  TextColumn get steps => text().nullable()();

  /// Completion timestamp as ISO8601 string (null if not completed)
  TextColumn get completedAt => text().nullable()();

  /// Owning Supabase user id (for RLS), '' before auth is known.
  TextColumn get userId => text().withDefault(const Constant(''))();

  /// Sync status: 0=synced, 1=created, 2=updated, 3=deleted
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
