import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../../models/task_list.dart';

/// Exception thrown when API requests receive an unauthorized response.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Unauthorized']);
  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown when API requests are rate limited.
class RateLimitedException implements Exception {
  const RateLimitedException([this.retryAfter]);
  final Duration? retryAfter;

  @override
  String toString() {
    return 'RateLimitedException${retryAfter != null ? ': retry after $retryAfter' : ''}';
  }
}

/// Exception thrown when API requests fail due to server errors.
class ServerException implements Exception {
  const ServerException(this.statusCode, [this.message]);
  final int statusCode;
  final String? message;

  @override
  String toString() {
    return 'ServerException: $statusCode${message != null ? ' - $message' : ''}';
  }
}

/// Client for the Google Tasks API.
///
/// Handles all HTTP communication with the Google Tasks REST API.
/// The access token must be valid and non-expired; use TokenManager to ensure
/// token validity before making requests.
class GoogleTasksApi {
  GoogleTasksApi({required String accessToken}) : _accessToken = accessToken;

  final String _accessToken;

  static const String _baseUrl = 'https://www.googleapis.com/tasks/v1';
  static const String _tasklistsPath = '/users/@me/lists';
  static const String _tasksPath = '/lists';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  Uri _tasksUri(String taskListId) =>
      Uri.parse('$_baseUrl$_tasksPath/$taskListId/tasks');

  Uri _taskUri(String taskListId, String taskId) =>
      Uri.parse('$_baseUrl$_tasksPath/$taskListId/tasks/$taskId');

  Uri _tasklistsUri() => Uri.parse('$_baseUrl$_tasklistsPath');

  Uri _tasklistUri(String taskListId) =>
      Uri.parse('$_baseUrl$_tasklistsPath/$taskListId');

  /// Handles HTTP response and throws appropriate exceptions.
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const UnauthorizedException();
    }

    if (response.statusCode == 429) {
      // Try to parse Retry-After header
      final retryAfter = response.headers['retry-after'];
      if (retryAfter != null) {
        final seconds = int.tryParse(retryAfter);
        if (seconds != null) {
          throw RateLimitedException(Duration(seconds: seconds));
        }
      }
      throw const RateLimitedException();
    }

    if (response.statusCode >= 500) {
      throw ServerException(response.statusCode, response.body);
    }

    if (response.statusCode >= 400) {
      try {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? response.body;
        throw ServerException(response.statusCode, errorMessage);
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(response.statusCode, response.body);
      }
    }

    return jsonDecode(response.body);
  }

  /// Lists all task lists for the authenticated user.
  Future<List<TaskList>> getTaskLists() async {
    final response = await http.get(_tasklistsUri(), headers: _headers);

    final data = _handleResponse(response) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => _parseTaskList(item as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new task list.
  Future<TaskList> createTaskList(String title) async {
    final body = jsonEncode({'title': title});

    final response = await http.post(
      _tasklistsUri(),
      headers: _headers,
      body: body,
    );

    final data = _handleResponse(response) as Map<String, dynamic>;
    return _parseTaskList(data);
  }

  /// Updates an existing task list.
  Future<TaskList> updateTaskList(String taskListId, String title) async {
    final body = jsonEncode({'title': title});

    final response = await http.put(
      _tasklistUri(taskListId),
      headers: _headers,
      body: body,
    );

    final data = _handleResponse(response) as Map<String, dynamic>;
    return _parseTaskList(data);
  }

  /// Deletes a task list.
  Future<void> deleteTaskList(String taskListId) async {
    final response = await http.delete(
      _tasklistUri(taskListId),
      headers: _headers,
    );

    _handleResponse(response);
  }

  /// Fetches all tasks from a specific task list.
  ///
  /// Note: Google Tasks API doesn't support fetching all tasks at once;
  /// this method fetches the first page. For full sync, consider using
  /// the sync service which handles pagination.
  Future<List<Task>> getTasks(String taskListId) async {
    final response = await http.get(_tasksUri(taskListId), headers: _headers);

    final data = _handleResponse(response) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => _parseTask(item as Map<String, dynamic>, taskListId))
        .toList();
  }

  /// Creates a new task in the specified task list.
  Future<Task> createTask(String taskListId, Task task) async {
    final body = _taskToJson(task, excludeId: true);

    final response = await http.post(
      _tasksUri(taskListId),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = _handleResponse(response) as Map<String, dynamic>;
    return _parseTask(data, taskListId);
  }

  /// Updates an existing task.
  Future<Task> updateTask(String taskListId, Task task) async {
    final body = _taskToJson(task);

    final response = await http.put(
      _taskUri(taskListId, task.id),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = _handleResponse(response) as Map<String, dynamic>;
    return _parseTask(data, taskListId);
  }

  /// Deletes a task.
  Future<void> deleteTask(String taskListId, String taskId) async {
    final response = await http.delete(
      _taskUri(taskListId, taskId),
      headers: _headers,
    );

    _handleResponse(response);
  }

  /// Parses a task list from JSON response.
  TaskList _parseTaskList(Map<String, dynamic> json) {
    return TaskList(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      updated:
          DateTime.tryParse(json['updated'] as String? ?? '') ?? DateTime.now(),
      isDefault: json['kind'] == 'tasks#taskList',
    );
  }

  /// Parses a task from JSON response.
  Task _parseTask(Map<String, dynamic> json, String taskListId) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      due: json['due'] != null
          ? DateTime.tryParse(json['due'] as String)
          : null,
      status: json['status'] as String? ?? 'needsAction',
      updated:
          DateTime.tryParse(json['updated'] as String? ?? '') ?? DateTime.now(),
      taskListId: taskListId,
      parentId: json['parent'] as String?,
      position: 0,
    );
  }

  /// Converts a Task to JSON for API requests.
  Map<String, dynamic> _taskToJson(Task task, {bool excludeId = false}) {
    final json = <String, dynamic>{
      'title': task.title,
      'notes': task.notes,
      'status': task.status,
    };

    if (!excludeId && task.id.isNotEmpty) {
      json['id'] = task.id;
    }

    if (task.due != null) {
      json['due'] = task.due!.toUtc().toIso8601String();
    }

    if (task.parentId != null) {
      json['parent'] = task.parentId;
    }

    return json;
  }
}
