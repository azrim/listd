import 'package:flutter/foundation.dart';
import 'sync_status.dart';
import 'task_sort_mode.dart';

/// Repeat type for recurring tasks.
enum RepeatType { daily, weekly, monthly, yearly, custom }

/// Configuration for repeating tasks.
@immutable
class RepeatConfig {
  const RepeatConfig({required this.type, this.interval = 1, this.weekDays});

  final RepeatType type;
  final int interval;
  final List<int>? weekDays; // 1=Mon, 7=Sun

  /// Creates a copy with updated fields.
  RepeatConfig copyWith({
    RepeatType? type,
    int? interval,
    List<int>? weekDays,
    bool clearWeekDays = false,
  }) {
    return RepeatConfig(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      weekDays: clearWeekDays ? null : (weekDays ?? this.weekDays),
    );
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'interval': interval,
    'weekDays': weekDays,
  };

  /// Deserialize from JSON map.
  factory RepeatConfig.fromJson(Map<String, dynamic> json) {
    return RepeatConfig(
      type: RepeatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RepeatType.daily,
      ),
      interval: json['interval'] as int? ?? 1,
      weekDays: (json['weekDays'] as List?)?.cast<int>(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepeatConfig &&
        other.type == type &&
        other.interval == interval &&
        _listEquals(other.weekDays, weekDays);
  }

  @override
  int get hashCode => Object.hash(type, interval, weekDays);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A step/subtask within a task.
@immutable
class TaskStep {
  const TaskStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.position = 0,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final int position;

  /// Whether this step is a link (URL).
  bool get isLink =>
      title.startsWith('http://') || title.startsWith('https://');

  /// Creates a copy with updated fields.
  TaskStep copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? position,
  }) {
    return TaskStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskStep &&
        other.id == id &&
        other.title == title &&
        other.isCompleted == isCompleted &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(id, title, isCompleted, position);

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'position': position,
  };

  /// Deserialize from JSON map.
  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
    );
  }
}

/// Represents a task in the application domain model.
///
/// This is the core domain model used throughout the application for tasks.
/// It is distinct from the Drift table model which handles database persistence.
@immutable
class Task {
  Task({
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
    this.isStarred = false,
    this.manuallyAddedToToday = false,
    this.steps = const [],
    this.reminder,
    this.repeat,
    this.tags = const [],
    this.userId = '',
  }) : assert(id.isNotEmpty, 'Task ID cannot be empty'),
       assert(title.isNotEmpty, 'Task title cannot be empty');

  /// Unique identifier for the task
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

  /// Position within the task list (for ordering).
  /// Uses double for fractional insertion (e.g. insert between 1024 and
  /// 2048 → 1536). New tasks get `max(position in list) + 1024`.
  final double position;

  /// Sync status with remote
  final SyncStatus syncStatus;

  /// Completion timestamp (null if not completed)
  final DateTime? completedAt;

  /// Whether this task is starred/favorited
  final bool isStarred;

  /// Whether this task was manually added to the Today smart bucket.
  final bool manuallyAddedToToday;

  /// Steps/subtasks within this task
  final List<TaskStep> steps;

  /// Reminder date+time
  final DateTime? reminder;

  /// Repeat configuration
  final RepeatConfig? repeat;

  /// Tags associated with this task
  final List<String> tags;

  /// User ID (for RLS in Supabase)
  final String userId;

  /// Whether this task is completed
  bool get isCompleted => status == 'completed';

  /// Whether this task is a subtask
  bool get isSubtask => parentId != null;

  /// Number of completed steps
  int get completedStepCount => steps.where((s) => s.isCompleted).length;

  /// Whether this task has any notes
  bool get hasNotes => notes.trim().isNotEmpty;

  /// Whether this task has a due date
  bool get hasDueDate => due != null;

  /// Whether this task has a reminder
  bool get hasReminder => reminder != null;

  /// Whether this task has repeat configuration
  bool get hasRepeat => repeat != null;

  /// Creates a copy with updated fields.
  Task copyWith({
    String? id,
    String? title,
    String? notes,
    bool clearNotes = false,
    DateTime? due,
    bool clearDue = false,
    String? status,
    DateTime? updated,
    String? taskListId,
    String? parentId,
    bool clearParentId = false,
    double? position,
    SyncStatus? syncStatus,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isStarred,
    bool? manuallyAddedToToday,
    List<TaskStep>? steps,
    DateTime? reminder,
    bool clearReminder = false,
    RepeatConfig? repeat,
    bool clearRepeat = false,
    List<String>? tags,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: clearNotes ? '' : (notes ?? this.notes),
      due: clearDue ? null : (due ?? this.due),
      status: status ?? this.status,
      updated: updated ?? this.updated,
      taskListId: taskListId ?? this.taskListId,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      position: position ?? this.position,
      syncStatus: syncStatus ?? this.syncStatus,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isStarred: isStarred ?? this.isStarred,
      manuallyAddedToToday: manuallyAddedToToday ?? this.manuallyAddedToToday,
      steps: steps ?? this.steps,
      reminder: clearReminder ? null : (reminder ?? this.reminder),
      repeat: clearRepeat ? null : (repeat ?? this.repeat),
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
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
        other.isStarred == isStarred &&
        other.manuallyAddedToToday == manuallyAddedToToday &&
        _listEqualsSteps(other.steps, steps) &&
        other.reminder == reminder &&
        other.repeat == repeat &&
        _listEquals(other.tags, tags) &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(
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
    isStarred,
    manuallyAddedToToday,
    steps,
    reminder,
    repeat,
    tags,
    userId,
  );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqualsSteps(List<TaskStep>? a, List<TaskStep>? b) {
    return _listEquals(a, b);
  }

  /// Stable comparator for the user-pickable task sort modes.
  ///
  /// Each mode falls back to `position` for ties so the ordering is
  /// deterministic even when the primary key collides (two tasks with
  /// the same due date, two starred tasks, etc.). Callers that want
  /// completed tasks at the bottom apply that as a separate preceding
  /// rule — this method just orders within the active and completed
  /// buckets.
  static int compareBy(Task a, Task b, TaskSortMode mode) {
    int byPosition() => a.position.compareTo(b.position);
    switch (mode) {
      case TaskSortMode.manual:
        return byPosition();
      case TaskSortMode.dueDate:
        if (a.due != null && b.due != null) {
          final c = a.due!.compareTo(b.due!);
          if (c != 0) return c;
        } else if (a.due != null) {
          return -1;
        } else if (b.due != null) {
          return 1;
        }
        return byPosition();
      case TaskSortMode.dateAdded:
        // Newest first — `updated` is the best proxy for creation
        // order Listd has on the model today.
        final c = b.updated.compareTo(a.updated);
        if (c != 0) return c;
        return byPosition();
      case TaskSortMode.alphabetical:
        final c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (c != 0) return c;
        return byPosition();
      case TaskSortMode.starredFirst:
        if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
        return byPosition();
    }
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, '
        'taskListId: $taskListId, steps: ${steps.length})';
  }
}
