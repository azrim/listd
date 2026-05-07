import '../../models/task.dart';
import '../../models/task_list.dart';

/// Represents the capabilities of a task provider implementation.
///
/// Used to check what operations a provider supports at runtime.
class ProviderCapabilities {
  const ProviderCapabilities({
    this.canCreateTasks = false,
    this.canUpdateTasks = false,
    this.canDeleteTasks = false,
    this.canCreateTaskLists = false,
    this.canUpdateTaskLists = false,
    this.canDeleteTaskLists = false,
    this.supportsOfflineSync = false,
  });

  /// Whether the provider can create new tasks.
  final bool canCreateTasks;

  /// Whether the provider can update existing tasks.
  final bool canUpdateTasks;

  /// Whether the provider can delete tasks.
  final bool canDeleteTasks;

  /// Whether the provider can create new task lists.
  final bool canCreateTaskLists;

  /// Whether the provider can update existing task lists.
  final bool canUpdateTaskLists;

  /// Whether the provider can delete task lists.
  final bool canDeleteTaskLists;

  /// Whether the provider supports offline sync.
  final bool supportsOfflineSync;
}

/// Abstract interface for task providers.
///
/// This interface enables provider-agnostic design, allowing the application
/// to work with different backends (Google Tasks, local-only, etc.) through
/// a common interface.
///
/// All methods that communicate with the remote server return domain models
/// and throw exceptions on failure.
abstract class ITaskProvider {
  /// Returns the capabilities of this provider.
  ProviderCapabilities get capabilities;

  /// Retrieves all task lists from the remote source.
  ///
  /// Returns a list of [TaskList] objects.
  /// Throws [Exception] if the request fails.
  Future<List<TaskList>> getTaskLists();

  /// Retrieves all tasks from a specific task list.
  ///
  /// [taskListId] - The ID of the task list to fetch tasks from.
  ///
  /// Returns a list of [Task] objects within the specified task list.
  /// Throws [Exception] if the request fails.
  Future<List<Task>> getTasks(String taskListId);

  /// Creates a new task.
  ///
  /// [taskListId] - The ID of the task list to add the task to.
  /// [task] - The task to create (ID should be empty/null for new tasks).
  ///
  /// Returns the created [Task] with its assigned ID.
  /// Throws [Exception] if the request fails.
  Future<Task> createTask(String taskListId, Task task);

  /// Updates an existing task.
  ///
  /// [taskListId] - The ID of the task list containing the task.
  /// [task] - The task with updated fields.
  ///
  /// Returns the updated [Task].
  /// Throws [Exception] if the request fails.
  Future<Task> updateTask(String taskListId, Task task);

  /// Deletes a task.
  ///
  /// [taskListId] - The ID of the task list containing the task.
  /// [taskId] - The ID of the task to delete.
  ///
  /// Throws [Exception] if the request fails.
  Future<void> deleteTask(String taskListId, String taskId);

  /// Performs a full sync between local and remote data.
  ///
  /// [localTaskLists] - Current local task lists.
  /// [localTasks] - Current local tasks (grouped by task list ID).
  ///
  /// Returns a [SyncResult] containing the merged data.
  /// This is called by the sync service to reconcile local and remote state.
  Future<SyncResult> sync(
    List<TaskList> localTaskLists,
    Map<String, List<Task>> localTasks,
  );
}

/// Result of a sync operation between local and remote data.
class SyncResult {
  const SyncResult({
    required this.taskLists,
    required this.tasks,
    this.deletedTaskListIds = const [],
    this.deletedTaskIds = const [],
  });

  /// Updated task lists from the remote source.
  final List<TaskList> taskLists;

  /// Updated tasks from the remote source (grouped by task list ID).
  final Map<String, List<Task>> tasks;

  /// IDs of task lists that were deleted remotely.
  final List<String> deletedTaskListIds;

  /// IDs of tasks that were deleted remotely.
  final List<String> deletedTaskIds;
}
