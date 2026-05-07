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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future schema migrations go here
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
