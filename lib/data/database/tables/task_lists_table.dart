import 'package:drift/drift.dart';

/// Drift table definition for task lists.
///
/// This table stores task list entities with sync status for tracking
/// changes that need to be pushed to Supabase.
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

  @override
  Set<Column> get primaryKey => {id};
}
