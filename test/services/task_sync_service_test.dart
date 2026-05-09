import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/data/database/app_database.dart';
import 'package:listd/data/database/daos/task_dao.dart';
import 'package:listd/data/database/daos/task_list_dao.dart';
import 'package:listd/models/sync_status.dart';
import 'package:listd/models/task.dart';
import 'package:listd/models/task_list.dart';
import 'package:listd/services/sync/task_sync_service.dart';

/// Hand-rolled fake [TaskSyncBackend] so the sync service can be exercised
/// without a live Supabase client.
///
/// Push calls are gated on per-id [Completer]s. The test arms a completer
/// for each id it expects to push, then calls [completeCall] to release
/// the mock so the in-flight push resolves.
class _FakeBackend implements TaskSyncBackend {
  final List<String> createListCalls = [];
  final List<String> updateListCalls = [];
  final List<String> deleteListCalls = [];
  final List<String> createTaskCalls = [];
  final List<String> updateTaskCalls = [];
  final List<String> deleteTaskCalls = [];

  /// Completers gating each `createTaskList(id)` call. Pre-populate to
  /// gate; leave empty for an immediate completion.
  final Map<String, Completer<void>> createListGates = {};

  /// Fires the first time `createTaskList` is invoked. Tests await this
  /// to know the in-flight cycle has actually started.
  final Completer<void> firstCreateListCallStarted = Completer<void>();

  /// Set by the test if `getTaskLists` / `getAllTasks` should return rows.
  List<TaskList> remoteTaskLists = const [];
  List<Task> remoteTasks = const [];

  @override
  bool isAuthenticated = true;

  void completeCall(String id) {
    final gate = createListGates.remove(id);
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<TaskList> createTaskList(TaskList taskList) async {
    createListCalls.add(taskList.id);
    if (!firstCreateListCallStarted.isCompleted) {
      firstCreateListCallStarted.complete();
    }
    final gate = createListGates[taskList.id];
    if (gate != null) await gate.future;
    return taskList.copyWith(syncStatus: SyncStatus.synced);
  }

  @override
  Future<TaskList> updateTaskList(TaskList taskList) async {
    updateListCalls.add(taskList.id);
    return taskList.copyWith(syncStatus: SyncStatus.synced);
  }

  @override
  Future<void> deleteTaskList(String taskListId) async {
    deleteListCalls.add(taskListId);
  }

  @override
  Future<Task> createTask(String taskListId, Task task) async {
    createTaskCalls.add(task.id);
    return task.copyWith(syncStatus: SyncStatus.synced);
  }

  @override
  Future<Task> updateTask(String taskListId, Task task) async {
    updateTaskCalls.add(task.id);
    return task.copyWith(syncStatus: SyncStatus.synced);
  }

  @override
  Future<void> deleteTask(String taskListId, String taskId) async {
    deleteTaskCalls.add(taskId);
  }

  @override
  Future<List<TaskList>> getTaskLists() async => remoteTaskLists;

  @override
  Future<List<Task>> getAllTasks() async => remoteTasks;
}

/// Polls until [check] returns true or [timeout] elapses.
Future<void> _waitFor(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not satisfied within $timeout');
    }
    await Future<void>.delayed(step);
  }
}

void main() {
  late AppDatabase db;
  late TaskListDao taskListDao;
  late TaskDao taskDao;
  late _FakeBackend backend;
  late TaskSyncService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskListDao = TaskListDao(db);
    taskDao = TaskDao(db);
    backend = _FakeBackend();
    service = TaskSyncService(
      taskDao: taskDao,
      taskListDao: taskListDao,
      taskProvider: backend,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  TaskList pendingList(String id) => TaskList(
    id: id,
    title: 'list-$id',
    updated: DateTime.now(),
    syncStatus: SyncStatus.created,
  );

  test(
    'mutation during in-flight sync is pushed once the cycle finishes',
    () async {
      // Pre-populate one pending row and gate its push so the cycle
      // stays in flight until the test releases it.
      await taskListDao.upsertTaskList(pendingList('L1'));
      backend.createListGates['L1'] = Completer<void>();
      backend.createListGates['L2'] = Completer<void>();

      // Kick off the first cycle (await it later so we can observe when
      // it finishes).
      final firstCycle = service.syncAll();

      // Wait for the cycle to actually begin pushing L1.
      await backend.firstCreateListCallStarted.future.timeout(
        const Duration(seconds: 1),
      );
      expect(service.isSyncing.value, isTrue);

      // While L1's push is in flight, a second mutation lands and a
      // new sync gets requested. This is exactly what the debounced
      // timer fires off when a mutation lands mid-cycle.
      await taskListDao.upsertTaskList(pendingList('L2'));
      final droppedCycle = service.syncAll();

      // The mid-cycle syncAll() must early-return without doing work
      // (only one cycle runs at a time).
      final droppedSummary = await droppedCycle;
      expect(droppedSummary.taskListsPushed, 0);
      expect(backend.createListCalls, equals(['L1']));

      // Release L1; the in-flight cycle finishes, and the service must
      // re-arm a follow-up sync that picks up L2. Without the
      // _pendingResync flag, this never happens and L2 sits unsynced.
      backend.completeCall('L1');
      await firstCycle;

      await _waitFor(
        () => backend.createListCalls.contains('L2'),
        timeout: const Duration(seconds: 2),
      );
      backend.completeCall('L2');

      await _waitFor(() => !service.isSyncing.value);
      expect(backend.createListCalls, equals(['L1', 'L2']));

      // Both rows should now be marked synced in Drift.
      final entries = await taskListDao.getAllTaskLists();
      expect(entries.map((e) => e.syncStatus), everyElement(0));
    },
  );

  test('syncAll is a no-op when no rows are pending', () async {
    final summary = await service.syncAll();

    expect(summary.taskListsPushed, 0);
    expect(summary.tasksPushed, 0);
    expect(backend.createListCalls, isEmpty);
    expect(service.isSyncing.value, isFalse);
  });

  test('syncAll early-returns when unauthenticated', () async {
    backend.isAuthenticated = false;
    await taskListDao.upsertTaskList(pendingList('L1'));

    final summary = await service.syncAll();

    expect(summary.taskListsPushed, 0);
    expect(backend.createListCalls, isEmpty);
  });

  test('scheduleSync coalesces rapid bursts into one cycle', () async {
    await taskListDao.upsertTaskList(pendingList('L1'));

    // Three rapid schedules within the debounce window should fire once.
    service.scheduleSync(delay: const Duration(milliseconds: 30));
    service.scheduleSync(delay: const Duration(milliseconds: 30));
    service.scheduleSync(delay: const Duration(milliseconds: 30));

    await _waitFor(() => backend.createListCalls.isNotEmpty);
    await _waitFor(() => !service.isSyncing.value);

    expect(backend.createListCalls, equals(['L1']));
  });
}
