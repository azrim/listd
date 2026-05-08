import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../models/sync_status.dart';
import '../tasks/task_provider.dart';

/// Supabase-based task provider implementing ITaskProvider.
///
/// Uses Supabase PostgREST client for CRUD operations and
/// Supabase Auth for user authentication.
class SupabaseTasksProvider implements ITaskProvider {
  SupabaseTasksProvider(this._client);

  final SupabaseClient _client;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
    canCreateTasks: true,
    canUpdateTasks: true,
    canDeleteTasks: true,
    canCreateTaskLists: true,
    canUpdateTaskLists: true,
    canDeleteTaskLists: true,
    supportsOfflineSync: false, // TODO: implement with Drift cache
  );

  /// Get current user ID (throws if not authenticated).
  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw UnauthorizedException('Not authenticated');
    }
    return user.id;
  }

  @override
  Future<List<TaskList>> getTaskLists() async {
    try {
      final response = await _client
          .from('task_lists')
          .select()
          .eq('user_id', currentUserId)
          .order('position');

      return (response as List).map((row) => _mapToTaskList(row)).toList();
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  @override
  Future<List<Task>> getTasks(String taskListId) async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('task_list_id', taskListId)
          .eq('user_id', currentUserId)
          .order('position');

      return (response as List).map((row) => _mapToTask(row)).toList();
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  @override
  Future<Task> createTask(String taskListId, Task task) async {
    try {
      // Note: sync_status is a Drift-only column for offline tracking and
      // does NOT exist server-side. Including it crashes the INSERT with
      // "column tasks.sync_status does not exist" and leaves TasksNotifier
      // in an error state (which surfaces as "Failed to load tasks").
      final data = {
        'user_id': currentUserId,
        'task_list_id': taskListId,
        'title': task.title,
        'notes': task.notes,
        'due': task.due?.toIso8601String(),
        'is_completed': task.isCompleted,
        'is_important': task.isStarred,
        'is_my_day': false,
        'position': task.position,
        'parent_id': task.parentId,
        'completed_at': task.completedAt?.toIso8601String(),
        'reminder': task.reminder?.toIso8601String(),
        'repeat_config': task.repeat?.toJson() != null
            ? jsonEncode(task.repeat!.toJson())
            : null,
        'tags': task.tags,
      };

      final response = await _client
          .from('tasks')
          .insert(data)
          .select()
          .single();

      return _mapToTask(response);
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  @override
  Future<Task> updateTask(String taskListId, Task task) async {
    try {
      final data = {
        'title': task.title,
        'notes': task.notes,
        'due': task.due?.toIso8601String(),
        'is_completed': task.isCompleted,
        'is_important': task.isStarred,
        'position': task.position,
        'parent_id': task.parentId,
        'completed_at': task.completedAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'reminder': task.reminder?.toIso8601String(),
        'repeat_config': task.repeat?.toJson() != null
            ? jsonEncode(task.repeat!.toJson())
            : null,
        'tags': task.tags,
      };

      final response = await _client
          .from('tasks')
          .update(data)
          .eq('id', task.id)
          .eq('user_id', currentUserId)
          .select()
          .single();

      return _mapToTask(response);
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> deleteTask(String taskListId, String taskId) async {
    try {
      await _client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', currentUserId);
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  @override
  Future<SyncResult> sync(
    List<TaskList> localTaskLists,
    Map<String, List<Task>> localTasks,
  ) async {
    // TODO: Implement sync with Drift local cache
    // For now, just return current remote state
    final taskLists = await getTaskLists();

    // Fetch all tasks in one query to avoid N+1 problem
    final allTasksResponse = await _client
        .from('tasks')
        .select()
        .eq('user_id', currentUserId)
        .order('task_list_id,position');

    final tasks = <String, List<Task>>{};
    for (final row in allTasksResponse as List) {
      final task = _mapToTask(row);
      if (!tasks.containsKey(task.taskListId)) {
        tasks[task.taskListId] = [];
      }
      tasks[task.taskListId]!.add(task);
    }

    return SyncResult(taskLists: taskLists, tasks: tasks);
  }

  // ── Task List Operations ──

  /// Creates a new task list.
  Future<TaskList> createTaskList(String title) async {
    try {
      final data = {
        'user_id': currentUserId,
        'title': title,
        'is_default': false,
        'position': 0,
      };

      final response = await _client
          .from('task_lists')
          .insert(data)
          .select()
          .single();

      return _mapToTaskList(response);
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  /// Updates an existing task list.
  Future<TaskList> updateTaskList(TaskList taskList) async {
    try {
      final data = {
        'title': taskList.title,
        'is_default': taskList.isDefault,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('task_lists')
          .update(data)
          .eq('id', taskList.id)
          .eq('user_id', currentUserId)
          .select()
          .single();

      return _mapToTaskList(response);
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  /// Deletes a task list.
  Future<void> deleteTaskList(String taskListId) async {
    try {
      await _client
          .from('task_lists')
          .delete()
          .eq('id', taskListId)
          .eq('user_id', currentUserId);
    } on PostgrestException catch (e) {
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      throw ServerException(e.message);
    }
  }

  // ── Mappers ──

  TaskList _mapToTaskList(Map<String, dynamic> row) {
    return TaskList(
      id: row['id'] as String,
      title: row['title'] as String,
      updated: DateTime.parse(row['updated_at'] as String),
      isDefault: row['is_default'] as bool? ?? false,
    );
  }

  Task _mapToTask(Map<String, dynamic> row) {
    // Parse repeat config from JSON string
    RepeatConfig? repeat;
    if (row['repeat_config'] != null) {
      try {
        final json =
            jsonDecode(row['repeat_config'] as String) as Map<String, dynamic>;
        repeat = RepeatConfig.fromJson(json);
      } catch (_) {
        repeat = null;
      }
    }

    // Parse tags from array
    List<String> tags = [];
    if (row['tags'] != null) {
      if (row['tags'] is List) {
        tags = (row['tags'] as List).cast<String>();
      }
    }

    // Parse steps from JSON array
    List<TaskStep> steps = [];
    if (row['steps'] != null && row['steps'] is List) {
      steps = (row['steps'] as List).map((s) {
        if (s is Map) {
          return TaskStep.fromJson(s as Map<String, dynamic>);
        }
        return TaskStep(id: s.toString(), title: s.toString());
      }).toList();
    }

    // Parse sync status from integer
    SyncStatus syncStatus = SyncStatus.synced;
    if (row['sync_status'] != null) {
      syncStatus = SyncStatus.fromValue(row['sync_status']);
    }

    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      notes: row['notes'] as String? ?? '',
      due: row['due'] != null ? DateTime.parse(row['due'] as String) : null,
      status: row['is_completed'] == true ? 'completed' : 'needsAction',
      updated: DateTime.parse(row['updated_at'] as String),
      taskListId: row['task_list_id'] as String,
      position: row['position'] as int? ?? 0,
      isStarred: row['is_important'] as bool? ?? false,
      reminder: row['reminder'] != null
          ? DateTime.parse(row['reminder'] as String)
          : null,
      repeat: repeat,
      tags: tags,
      steps: steps,
      parentId: row['parent_id'],
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      syncStatus: syncStatus,
    );
  }
}

/// Exception for authentication errors.
class UnauthorizedException implements Exception {
  const UnauthorizedException(this.message);
  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception for server/database errors.
class ServerException implements Exception {
  const ServerException(this.message);
  final String message;

  @override
  String toString() => 'ServerException: $message';
}
