import 'package:flutter/foundation.dart';
import 'sync_status.dart';

/// Represents a task in the Google Tasks domain model.
///
/// This is the core domain model used throughout the application for tasks.
/// It is distinct from the Drift table model which handles database persistence.
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.due,
    this.status = 'needsAction',
    required this.updated,
    required this.taskListId,
    this.parentId,
    this.position = 0,
    this.syncStatus = SyncStatus.synced,
    this.completedAt,
    this.subtaskCount = 0,
    this.isStarred = false,
  });

  /// Unique identifier for the task (Google Tasks API format or UUID)
  final String id;

  /// Task title/text
  final String title;

  /// Additional notes or description
  final String notes;

  /// Due date (null if no due date set)
  final DateTime? due;

  /// Completion status: 'needsAction' or 'completed'
  final String status;

  /// Last update timestamp
  final DateTime updated;

  /// Parent task list ID this task belongs to
  final String taskListId;

  /// Parent task ID (for subtasks), null for top-level tasks
  final String? parentId;

  /// Position within the task list (for ordering)
  final int position;

  /// Sync status with remote
  final SyncStatus syncStatus;

  /// Completion timestamp (null if not completed)
  final DateTime? completedAt;

  /// Number of subtasks for this task
  final int subtaskCount;

  /// Whether this task is starred/favorited
  final bool isStarred;

  /// Whether this task is completed
  bool get isCompleted => status == 'completed';

  /// Whether this task is a subtask
  bool get isSubtask => parentId != null;

  /// Creates a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? due,
    bool clearDue = false,
    String? status,
    DateTime? updated,
    String? taskListId,
    String? parentId,
    bool clearParentId = false,
    int? position,
    SyncStatus? syncStatus,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? subtaskCount,
    bool? isStarred,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      due: clearDue ? null : (due ?? this.due),
      status: status ?? this.status,
      updated: updated ?? this.updated,
      taskListId: taskListId ?? this.taskListId,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      position: position ?? this.position,
      syncStatus: syncStatus ?? this.syncStatus,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      subtaskCount: subtaskCount ?? this.subtaskCount,
      isStarred: isStarred ?? this.isStarred,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.notes == notes &&
        other.due == due &&
        other.status == status &&
        other.updated == updated &&
        other.taskListId == taskListId &&
        other.parentId == parentId &&
        other.position == position &&
        other.syncStatus == syncStatus &&
        other.completedAt == completedAt &&
        other.subtaskCount == subtaskCount &&
        other.isStarred == isStarred;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      notes,
      due,
      status,
      updated,
      taskListId,
      parentId,
      position,
      syncStatus,
      completedAt,
      subtaskCount,
      isStarred,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, '
        'taskListId: $taskListId, syncStatus: $syncStatus)';
  }
}
