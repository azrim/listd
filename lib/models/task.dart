import 'package:flutter/foundation.dart';
import 'sync_status.dart';

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

  /// Position within the task list (for ordering)
  final int position;

  /// Sync status with remote
  final SyncStatus syncStatus;

  /// Completion timestamp (null if not completed)
  final DateTime? completedAt;

  /// Whether this task is starred/favorited
  final bool isStarred;

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
    int? position,
    SyncStatus? syncStatus,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isStarred,
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

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, '
        'taskListId: $taskListId, steps: ${steps.length})';
  }
}
