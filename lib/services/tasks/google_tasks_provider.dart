import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'google_tasks_api.dart';
import 'task_provider.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../models/sync_status.dart';
import '../auth/token_manager.dart';

/// Provider for GoogleTasksApi.
///
/// Creates an API client with the current valid access token.
/// Note: The token is refreshed automatically if needed by TokenManager.
final googleTasksApiProvider = FutureProvider<GoogleTasksApi>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final accessToken = await tokenManager.getValidAccessToken();

  if (accessToken == null) {
    throw const UnauthorizedException('Not authenticated');
  }

  return GoogleTasksApi(accessToken: accessToken);
});

/// Provider for GoogleTasksProvider.
///
/// Wraps the Google Tasks API with the ITaskProvider interface.
final googleTasksProvider = Provider<ITaskProvider>((ref) {
  final apiAsync = ref.watch(googleTasksApiProvider);

  return GoogleTasksProvider(api: apiAsync.valueOrNull);
});

/// Implementation of ITaskProvider using Google Tasks API.
class GoogleTasksProvider implements ITaskProvider {
  GoogleTasksProvider({required GoogleTasksApi? api}) : _api = api;

  final GoogleTasksApi? _api;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
    canCreateTasks: true,
    canUpdateTasks: true,
    canDeleteTasks: true,
    canCreateTaskLists: false,
    canUpdateTaskLists: false,
    canDeleteTaskLists: false,
    supportsOfflineSync: false,
  );

  void _ensureAvailable() {
    if (_api == null) {
      throw const UnauthorizedException('Google Tasks API not available');
    }
  }

  @override
  Future<List<TaskList>> getTaskLists() async {
    _ensureAvailable();
    final taskLists = await _api!.getTaskLists();

    // Mark remote task lists as synced
    return taskLists
        .map((tl) => tl.copyWith(syncStatus: SyncStatus.synced))
        .toList();
  }

  @override
  Future<List<Task>> getTasks(String taskListId) async {
    _ensureAvailable();
    final tasks = await _api!.getTasks(taskListId);

    // Add taskListId and mark as synced
    return tasks
        .map(
          (t) =>
              t.copyWith(taskListId: taskListId, syncStatus: SyncStatus.synced),
        )
        .toList();
  }

  @override
  Future<Task> createTask(String taskListId, Task task) async {
    _ensureAvailable();
    final createdTask = await _api!.createTask(taskListId, task);

    return createdTask.copyWith(
      taskListId: taskListId,
      syncStatus: SyncStatus.synced,
    );
  }

  @override
  Future<Task> updateTask(String taskListId, Task task) async {
    _ensureAvailable();
    final updatedTask = await _api!.updateTask(taskListId, task);

    return updatedTask.copyWith(
      taskListId: taskListId,
      syncStatus: SyncStatus.synced,
    );
  }

  @override
  Future<void> deleteTask(String taskListId, String taskId) async {
    _ensureAvailable();
    await _api!.deleteTask(taskListId, taskId);
  }

  @override
  Future<SyncResult> sync(
    List<TaskList> localTaskLists,
    Map<String, List<Task>> localTasks,
  ) async {
    _ensureAvailable();

    // Pull all task lists from remote
    final remoteTaskLists = await _api!.getTaskLists();
    final syncedTaskLists = remoteTaskLists
        .map((tl) => tl.copyWith(syncStatus: SyncStatus.synced))
        .toList();

    // Collect all remote tasks
    final remoteTasks = <String, List<Task>>{};
    final deletedTaskListIds = <String>[];

    // Find task lists that exist locally but not remotely
    final remoteTaskListIds = syncedTaskLists.map((tl) => tl.id).toSet();
    for (final localList in localTaskLists) {
      if (!remoteTaskListIds.contains(localList.id) &&
          localList.syncStatus != SyncStatus.deleted) {
        deletedTaskListIds.add(localList.id);
      }
    }

    // Fetch tasks for each remote task list
    for (final taskList in syncedTaskLists) {
      final tasks = await _api.getTasks(taskList.id);
      remoteTasks[taskList.id] = tasks
          .map(
            (t) => t.copyWith(
              taskListId: taskList.id,
              syncStatus: SyncStatus.synced,
            ),
          )
          .toList();
    }

    return SyncResult(
      taskLists: syncedTaskLists,
      tasks: remoteTasks,
      deletedTaskListIds: deletedTaskListIds,
    );
  }
}
