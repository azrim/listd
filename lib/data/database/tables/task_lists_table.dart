import 'package:drift/drift.dart';

/// Drift table definition for task lists.
///
/// Local-first source of truth for task lists. `syncStatus` records
/// whether each row is `synced`, `created`, `updated`, or `deleted` so
/// that background sync can drain pending rows into Supabase.
@DataClassName('TaskListEntry')
class TaskLists extends Table {
  /// Unique identifier
  TextColumn get id => text()();

  /// Display title of the task list
  TextColumn get title => text()();

  /// Last update timestamp as ISO8601 string
  TextColumn get updated => text()();

  /// Sync status: 0=synced, 1=created, 2=updated, 3=deleted
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  /// Whether this is the user's default task list
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Owning Supabase user id (for RLS), '' before auth is known.
  TextColumn get userId => text().withDefault(const Constant(''))();

  /// Position within the sidebar for ordering
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
