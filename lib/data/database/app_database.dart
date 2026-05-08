import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/tasks_table.dart';
import 'tables/task_lists_table.dart';
import 'daos/task_dao.dart';
import 'daos/task_list_dao.dart';

part 'app_database.g.dart';

/// Main application database class.
///
/// This is the central database accessor that combines all tables and DAOs.
@DriftDatabase(tables: [Tasks, TaskLists], daos: [TaskDao, TaskListDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // v2: extend Tasks/TaskLists to mirror the full domain model so
          // Drift can be the local-first source of truth (rather than a
          // partial cache).
          await m.addColumn(tasks, tasks.reminder);
          await m.addColumn(tasks, tasks.repeatConfig);
          await m.addColumn(tasks, tasks.tags);
          await m.addColumn(tasks, tasks.steps);
          await m.addColumn(tasks, tasks.completedAt);
          await m.addColumn(tasks, tasks.userId);
          await m.addColumn(taskLists, taskLists.userId);
          await m.addColumn(taskLists, taskLists.position);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys for data integrity
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Opens a database connection using drift_flutter for cross-platform support.
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'listd_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}

/// Provider for the AppDatabase instance.
///
/// Use this to access the database throughout the application.
@pragma('vm:entry-point')
final databaseProvider = AppDatabase.new;
