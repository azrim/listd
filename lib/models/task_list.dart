import 'package:flutter/foundation.dart';
import 'sync_status.dart';

/// Represents a task list in the application domain model.
///
/// This is the core domain model used throughout the application for task lists.
/// It is distinct from the Drift table model which handles database persistence.
@immutable
class TaskList {
  const TaskList({
    required this.id,
    required this.title,
    required this.updated,
    this.syncStatus = SyncStatus.synced,
    this.isDefault = false,
    this.userId = '',
    this.position = 0,
  });

  /// Unique identifier for the task list
  final String id;

  /// Display title of the task list
  final String title;

  /// Last update timestamp
  final DateTime updated;

  /// Sync status with remote
  final SyncStatus syncStatus;

  /// Whether this is the user's default task list
  final bool isDefault;

  /// Owning Supabase user id (for RLS), '' before auth is known.
  final String userId;

  /// Position within the sidebar for ordering.
  final int position;

  /// Creates a copy with updated fields
  TaskList copyWith({
    String? id,
    String? title,
    DateTime? updated,
    SyncStatus? syncStatus,
    bool? isDefault,
    String? userId,
    int? position,
  }) {
    return TaskList(
      id: id ?? this.id,
      title: title ?? this.title,
      updated: updated ?? this.updated,
      syncStatus: syncStatus ?? this.syncStatus,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      position: position ?? this.position,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskList &&
        other.id == id &&
        other.title == title &&
        other.updated == updated &&
        other.syncStatus == syncStatus &&
        other.isDefault == isDefault &&
        other.userId == userId &&
        other.position == position;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      updated,
      syncStatus,
      isDefault,
      userId,
      position,
    );
  }

  @override
  String toString() {
    return 'TaskList(id: $id, title: $title, '
        'syncStatus: $syncStatus, isDefault: $isDefault)';
  }
}
