import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm/realm.dart';

import '../../config/app_config.dart';
import '../../data/realm/schemas/task_schema.dart';
import '../../data/realm/schemas/task_list_schema.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../tasks/task_provider.dart';

/// Provider for the Realm App instance.
final realmAppProvider = Provider<RealmApp>((ref) {
  return RealmApp(AppConfig.atlasAppId);
});

/// MongoDB Atlas Realm provider implementing ITaskProvider.
///
/// This provider uses MongoDB Atlas App Services with Realm SDK
/// for data storage and sync.
class MongoRealmProvider implements ITaskProvider {
  MongoRealmProvider(this._app) {
    _realm = _app.realm;
  }

  final RealmApp _app;
  late final Realm _realm;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        canCreateTasks: true,
        canUpdateTasks: true,
        canDeleteTasks: true,
        canCreateTaskLists: true,
        canUpdateTaskLists: true,
        canDeleteTaskLists: true,
        supportsOfflineSync: true,
      );

  @override
  Future<List<TaskList>> getTaskLists() async {
    final realmLists = _realm.all<TaskListSchema>().query('isDeleted == false');
    return realmLists.map(_toTaskList).toList();
  }

  @override
  Future<List<Task>> getTasks(String taskListId) async {
    final realmTasks = _realm
        .all<TaskSchema>()
        .query('taskListId == \$0 AND isDeleted == false', [taskListId]);
    return realmTasks.map(_toTask).toList();
  }

  @override
  Future<Task> createTask(String taskListId, Task task) async {
    final id = ObjectId();
    final now = DateTime.now();

    final realmTask = TaskSchema(
      id,
      task.title,
      task.notes,
      task.isCompleted,
      task.isStarred,
      false, // isMyDay
      taskListId,
      task.parentId ?? '',
      task.position,
      now,
      now,
      false, // isDeleted
      due: task.due,
    );

    _realm.write(() {
      _realm.add(realmTask);
    });

    return _toTask(realmTask);
  }

  @override
  Future<Task> updateTask(String taskListId, Task task) async {
    final realmTasks = _realm.all<TaskSchema>().query(
      'id == \$0',
      [ObjectId.fromHexString(task.id)],
    );

    if (realmTasks.isEmpty) {
      throw Exception('Task not found: ${task.id}');
    }

    final realmTask = realmTasks.first;
    final now = DateTime.now();

    _realm.write(() {
      realmTask.title = task.title;
      realmTask.notes = task.notes;
      realmTask.due = task.due;
      realmTask.isCompleted = task.isCompleted;
      realmTask.isImportant = task.isStarred;
      realmTask.position = task.position;
      realmTask.updatedAt = now;
    });

    return _toTask(realmTask);
  }

  @override
  Future<void> deleteTask(String taskListId, String taskId) async {
    final realmTasks = _realm.all<TaskSchema>().query(
      'id == \$0',
      [ObjectId.fromHexString(taskId)],
    );

    if (realmTasks.isEmpty) return;

    _realm.write(() {
      realmTasks.first.isDeleted = true;
    });
  }

  @override
  Future<SyncResult> sync(
    List<TaskList> localTaskLists,
    Map<String, List<Task>> localTasks,
  ) async {
    // Realm handles sync automatically via Device Sync
    // Just return current state
    final taskLists = await getTaskLists();
    final tasks = <String, List<Task>>{};

    for (final list in taskLists) {
      tasks[list.id] = await getTasks(list.id);
    }

    return SyncResult(taskLists: taskLists, tasks: tasks);
  }

  /// Creates a new task list.
  Future<TaskList> createTaskList(TaskList taskList) async {
    final id = ObjectId();
    final now = DateTime.now();

    final realmList = TaskListSchema(
      id,
      taskList.title,
      taskList.isDefault,
      0, // position
      now,
      now,
      false, // isDeleted
    );

    _realm.write(() {
      _realm.add(realmList);
    });

    return _toTaskList(realmList);
  }

  /// Updates an existing task list.
  Future<TaskList> updateTaskList(TaskList taskList) async {
    final realmLists = _realm.all<TaskListSchema>().query(
      'id == \$0',
      [ObjectId.fromHexString(taskList.id)],
    );

    if (realmLists.isEmpty) {
      throw Exception('Task list not found: ${taskList.id}');
    }

    final realmList = realmLists.first;
    final now = DateTime.now();

    _realm.write(() {
      realmList.title = taskList.title;
      realmList.isDefault = taskList.isDefault;
      realmList.updatedAt = now;
    });

    return _toTaskList(realmList);
  }

  /// Deletes a task list (soft delete).
  Future<void> deleteTaskList(String taskListId) async {
    final realmLists = _realm.all<TaskListSchema>().query(
      'id == \$0',
      [ObjectId.fromHexString(taskListId)],
    );

    if (realmLists.isEmpty) return;

    _realm.write(() {
      realmLists.first.isDeleted = true;
    });
  }

  // ── Converters ──

  TaskList _toTaskList(TaskListSchema schema) {
    return TaskList(
      id: schema.id.hexString,
      title: schema.title,
      updated: schema.updatedAt,
      isDefault: schema.isDefault,
    );
  }

  Task _toTask(TaskSchema schema) {
    return Task(
      id: schema.id.hexString,
      title: schema.title,
      notes: schema.notes,
      due: schema.due,
      status: schema.isCompleted ? 'completed' : 'needsAction',
      updated: schema.updatedAt,
      taskListId: schema.taskListId,
      parentId: schema.parentId.isEmpty ? null : schema.parentId,
      position: schema.position,
      isStarred: schema.isImportant,
    );
  }
}

/// Wrapper for MongoDB Atlas App Services App.
class RealmApp {
  RealmApp(this.appId);

  final String appId;
  Realm? _realm;
  User? _currentUser;

  /// Returns true if user is logged in.
  bool get isLoggedIn => _currentUser != null;

  /// Returns the current user, if logged in.
  User? get currentUser => _currentUser;

  /// Returns the Realm instance.
  Realm get realm {
    if (_realm == null) {
      throw StateError('Realm not initialized. Call login() first.');
    }
    return _realm!;
  }

  /// Logs in with Google credentials (ID token).
  Future<void> loginWithGoogle(String idToken) async {
    // TODO: Implement Google login via Atlas App Services
    // For now, this is a placeholder
    // Use: await app.login(Credentials.google(idToken));
    _currentUser = User(
      id: 'placeholder-user-id',
      createdAt: DateTime.now(),
    );
    _initRealm();
  }

  /// Logs out the current user.
  Future<void> logout() async {
    _realm?.close();
    _realm = null;
    _currentUser = null;
  }

  void _initRealm() {
    if (_currentUser == null) {
      throw StateError('Must login before initializing Realm');
    }

    final config = Configuration.local(
      [TaskSchema.schema, TaskListSchema.schema],
      path: 'lib/default.realm',
    );

    _realm = Realm(config);
  }
}

/// Placeholder user class for now.
class User {
  User({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;
}