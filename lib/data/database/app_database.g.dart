// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<String> due = GeneratedColumn<String>(
    'due',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('needsAction'),
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskListIdMeta = const VerificationMeta(
    'taskListId',
  );
  @override
  late final GeneratedColumn<String> taskListId = GeneratedColumn<String>(
    'task_list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _manuallyAddedToTodayMeta =
      const VerificationMeta('manuallyAddedToToday');
  @override
  late final GeneratedColumn<bool> manuallyAddedToToday = GeneratedColumn<bool>(
    'manually_added_to_today',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manually_added_to_today" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isStarredMeta = const VerificationMeta(
    'isStarred',
  );
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
    'is_starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderMeta = const VerificationMeta(
    'reminder',
  );
  @override
  late final GeneratedColumn<String> reminder = GeneratedColumn<String>(
    'reminder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatConfigMeta = const VerificationMeta(
    'repeatConfig',
  );
  @override
  late final GeneratedColumn<String> repeatConfig = GeneratedColumn<String>(
    'repeat_config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<String> steps = GeneratedColumn<String>(
    'steps',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    due,
    status,
    updated,
    taskListId,
    parentId,
    position,
    manuallyAddedToToday,
    isStarred,
    reminder,
    repeatConfig,
    tags,
    steps,
    completedAt,
    userId,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('task_list_id')) {
      context.handle(
        _taskListIdMeta,
        taskListId.isAcceptableOrUnknown(
          data['task_list_id']!,
          _taskListIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taskListIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('manually_added_to_today')) {
      context.handle(
        _manuallyAddedToTodayMeta,
        manuallyAddedToToday.isAcceptableOrUnknown(
          data['manually_added_to_today']!,
          _manuallyAddedToTodayMeta,
        ),
      );
    }
    if (data.containsKey('is_starred')) {
      context.handle(
        _isStarredMeta,
        isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta),
      );
    }
    if (data.containsKey('reminder')) {
      context.handle(
        _reminderMeta,
        reminder.isAcceptableOrUnknown(data['reminder']!, _reminderMeta),
      );
    }
    if (data.containsKey('repeat_config')) {
      context.handle(
        _repeatConfigMeta,
        repeatConfig.isAcceptableOrUnknown(
          data['repeat_config']!,
          _repeatConfigMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
      taskListId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_list_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
      manuallyAddedToToday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manually_added_to_today'],
      )!,
      isStarred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starred'],
      )!,
      reminder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder'],
      ),
      repeatConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_config'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}steps'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskEntry extends DataClass implements Insertable<TaskEntry> {
  /// Unique identifier
  final String id;

  /// Task title/text
  final String title;

  /// Additional notes or description
  final String notes;

  /// Due date as ISO8601 string (null if no due date)
  final String? due;

  /// Completion status: 'needsAction' or 'completed'
  final String status;

  /// Last update timestamp as ISO8601 string
  final String updated;

  /// Parent task list ID this task belongs to
  final String taskListId;

  /// Parent task ID for subtasks (null for top-level tasks)
  final String? parentId;

  /// Position within the task list for ordering.
  /// Uses a real (double) to support fractional insertion:
  /// inserting between positions 1024 and 2048 → 1536.
  final double position;

  /// Whether this task was manually added to the Today smart bucket.
  /// Default false — only true when the user explicitly drags/adds a
  /// task to Today that wouldn't otherwise appear there.
  final bool manuallyAddedToToday;

  /// Whether this task is starred/favorited
  final bool isStarred;

  /// Reminder timestamp as ISO8601 string (null if no reminder)
  final String? reminder;

  /// Repeat configuration as JSON string (null if not repeating)
  final String? repeatConfig;

  /// Tags encoded as a JSON array string (null/[] if no tags)
  final String? tags;

  /// Steps/subtasks encoded as a JSON array string (null/[] if no steps)
  final String? steps;

  /// Completion timestamp as ISO8601 string (null if not completed)
  final String? completedAt;

  /// Owning Supabase user id (for RLS), '' before auth is known.
  final String userId;

  /// Sync status: 0=synced, 1=created, 2=updated, 3=deleted
  final int syncStatus;
  const TaskEntry({
    required this.id,
    required this.title,
    required this.notes,
    this.due,
    required this.status,
    required this.updated,
    required this.taskListId,
    this.parentId,
    required this.position,
    required this.manuallyAddedToToday,
    required this.isStarred,
    this.reminder,
    this.repeatConfig,
    this.tags,
    this.steps,
    this.completedAt,
    required this.userId,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || due != null) {
      map['due'] = Variable<String>(due);
    }
    map['status'] = Variable<String>(status);
    map['updated'] = Variable<String>(updated);
    map['task_list_id'] = Variable<String>(taskListId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['position'] = Variable<double>(position);
    map['manually_added_to_today'] = Variable<bool>(manuallyAddedToToday);
    map['is_starred'] = Variable<bool>(isStarred);
    if (!nullToAbsent || reminder != null) {
      map['reminder'] = Variable<String>(reminder);
    }
    if (!nullToAbsent || repeatConfig != null) {
      map['repeat_config'] = Variable<String>(repeatConfig);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<String>(steps);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    map['user_id'] = Variable<String>(userId);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      notes: Value(notes),
      due: due == null && nullToAbsent ? const Value.absent() : Value(due),
      status: Value(status),
      updated: Value(updated),
      taskListId: Value(taskListId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      position: Value(position),
      manuallyAddedToToday: Value(manuallyAddedToToday),
      isStarred: Value(isStarred),
      reminder: reminder == null && nullToAbsent
          ? const Value.absent()
          : Value(reminder),
      repeatConfig: repeatConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatConfig),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      steps: steps == null && nullToAbsent
          ? const Value.absent()
          : Value(steps),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      userId: Value(userId),
      syncStatus: Value(syncStatus),
    );
  }

  factory TaskEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      due: serializer.fromJson<String?>(json['due']),
      status: serializer.fromJson<String>(json['status']),
      updated: serializer.fromJson<String>(json['updated']),
      taskListId: serializer.fromJson<String>(json['taskListId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      position: serializer.fromJson<double>(json['position']),
      manuallyAddedToToday: serializer.fromJson<bool>(
        json['manuallyAddedToToday'],
      ),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      reminder: serializer.fromJson<String?>(json['reminder']),
      repeatConfig: serializer.fromJson<String?>(json['repeatConfig']),
      tags: serializer.fromJson<String?>(json['tags']),
      steps: serializer.fromJson<String?>(json['steps']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'due': serializer.toJson<String?>(due),
      'status': serializer.toJson<String>(status),
      'updated': serializer.toJson<String>(updated),
      'taskListId': serializer.toJson<String>(taskListId),
      'parentId': serializer.toJson<String?>(parentId),
      'position': serializer.toJson<double>(position),
      'manuallyAddedToToday': serializer.toJson<bool>(manuallyAddedToToday),
      'isStarred': serializer.toJson<bool>(isStarred),
      'reminder': serializer.toJson<String?>(reminder),
      'repeatConfig': serializer.toJson<String?>(repeatConfig),
      'tags': serializer.toJson<String?>(tags),
      'steps': serializer.toJson<String?>(steps),
      'completedAt': serializer.toJson<String?>(completedAt),
      'userId': serializer.toJson<String>(userId),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  TaskEntry copyWith({
    String? id,
    String? title,
    String? notes,
    Value<String?> due = const Value.absent(),
    String? status,
    String? updated,
    String? taskListId,
    Value<String?> parentId = const Value.absent(),
    double? position,
    bool? manuallyAddedToToday,
    bool? isStarred,
    Value<String?> reminder = const Value.absent(),
    Value<String?> repeatConfig = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> steps = const Value.absent(),
    Value<String?> completedAt = const Value.absent(),
    String? userId,
    int? syncStatus,
  }) => TaskEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    due: due.present ? due.value : this.due,
    status: status ?? this.status,
    updated: updated ?? this.updated,
    taskListId: taskListId ?? this.taskListId,
    parentId: parentId.present ? parentId.value : this.parentId,
    position: position ?? this.position,
    manuallyAddedToToday: manuallyAddedToToday ?? this.manuallyAddedToToday,
    isStarred: isStarred ?? this.isStarred,
    reminder: reminder.present ? reminder.value : this.reminder,
    repeatConfig: repeatConfig.present ? repeatConfig.value : this.repeatConfig,
    tags: tags.present ? tags.value : this.tags,
    steps: steps.present ? steps.value : this.steps,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    userId: userId ?? this.userId,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TaskEntry copyWithCompanion(TasksCompanion data) {
    return TaskEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      due: data.due.present ? data.due.value : this.due,
      status: data.status.present ? data.status.value : this.status,
      updated: data.updated.present ? data.updated.value : this.updated,
      taskListId: data.taskListId.present
          ? data.taskListId.value
          : this.taskListId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      position: data.position.present ? data.position.value : this.position,
      manuallyAddedToToday: data.manuallyAddedToToday.present
          ? data.manuallyAddedToToday.value
          : this.manuallyAddedToToday,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      reminder: data.reminder.present ? data.reminder.value : this.reminder,
      repeatConfig: data.repeatConfig.present
          ? data.repeatConfig.value
          : this.repeatConfig,
      tags: data.tags.present ? data.tags.value : this.tags,
      steps: data.steps.present ? data.steps.value : this.steps,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('due: $due, ')
          ..write('status: $status, ')
          ..write('updated: $updated, ')
          ..write('taskListId: $taskListId, ')
          ..write('parentId: $parentId, ')
          ..write('position: $position, ')
          ..write('manuallyAddedToToday: $manuallyAddedToToday, ')
          ..write('isStarred: $isStarred, ')
          ..write('reminder: $reminder, ')
          ..write('repeatConfig: $repeatConfig, ')
          ..write('tags: $tags, ')
          ..write('steps: $steps, ')
          ..write('completedAt: $completedAt, ')
          ..write('userId: $userId, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
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
    manuallyAddedToToday,
    isStarred,
    reminder,
    repeatConfig,
    tags,
    steps,
    completedAt,
    userId,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.due == this.due &&
          other.status == this.status &&
          other.updated == this.updated &&
          other.taskListId == this.taskListId &&
          other.parentId == this.parentId &&
          other.position == this.position &&
          other.manuallyAddedToToday == this.manuallyAddedToToday &&
          other.isStarred == this.isStarred &&
          other.reminder == this.reminder &&
          other.repeatConfig == this.repeatConfig &&
          other.tags == this.tags &&
          other.steps == this.steps &&
          other.completedAt == this.completedAt &&
          other.userId == this.userId &&
          other.syncStatus == this.syncStatus);
}

class TasksCompanion extends UpdateCompanion<TaskEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> notes;
  final Value<String?> due;
  final Value<String> status;
  final Value<String> updated;
  final Value<String> taskListId;
  final Value<String?> parentId;
  final Value<double> position;
  final Value<bool> manuallyAddedToToday;
  final Value<bool> isStarred;
  final Value<String?> reminder;
  final Value<String?> repeatConfig;
  final Value<String?> tags;
  final Value<String?> steps;
  final Value<String?> completedAt;
  final Value<String> userId;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.due = const Value.absent(),
    this.status = const Value.absent(),
    this.updated = const Value.absent(),
    this.taskListId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.position = const Value.absent(),
    this.manuallyAddedToToday = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.reminder = const Value.absent(),
    this.repeatConfig = const Value.absent(),
    this.tags = const Value.absent(),
    this.steps = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.due = const Value.absent(),
    this.status = const Value.absent(),
    required String updated,
    required String taskListId,
    this.parentId = const Value.absent(),
    this.position = const Value.absent(),
    this.manuallyAddedToToday = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.reminder = const Value.absent(),
    this.repeatConfig = const Value.absent(),
    this.tags = const Value.absent(),
    this.steps = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updated = Value(updated),
       taskListId = Value(taskListId);
  static Insertable<TaskEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? due,
    Expression<String>? status,
    Expression<String>? updated,
    Expression<String>? taskListId,
    Expression<String>? parentId,
    Expression<double>? position,
    Expression<bool>? manuallyAddedToToday,
    Expression<bool>? isStarred,
    Expression<String>? reminder,
    Expression<String>? repeatConfig,
    Expression<String>? tags,
    Expression<String>? steps,
    Expression<String>? completedAt,
    Expression<String>? userId,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (due != null) 'due': due,
      if (status != null) 'status': status,
      if (updated != null) 'updated': updated,
      if (taskListId != null) 'task_list_id': taskListId,
      if (parentId != null) 'parent_id': parentId,
      if (position != null) 'position': position,
      if (manuallyAddedToToday != null)
        'manually_added_to_today': manuallyAddedToToday,
      if (isStarred != null) 'is_starred': isStarred,
      if (reminder != null) 'reminder': reminder,
      if (repeatConfig != null) 'repeat_config': repeatConfig,
      if (tags != null) 'tags': tags,
      if (steps != null) 'steps': steps,
      if (completedAt != null) 'completed_at': completedAt,
      if (userId != null) 'user_id': userId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? notes,
    Value<String?>? due,
    Value<String>? status,
    Value<String>? updated,
    Value<String>? taskListId,
    Value<String?>? parentId,
    Value<double>? position,
    Value<bool>? manuallyAddedToToday,
    Value<bool>? isStarred,
    Value<String?>? reminder,
    Value<String?>? repeatConfig,
    Value<String?>? tags,
    Value<String?>? steps,
    Value<String?>? completedAt,
    Value<String>? userId,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      due: due ?? this.due,
      status: status ?? this.status,
      updated: updated ?? this.updated,
      taskListId: taskListId ?? this.taskListId,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      manuallyAddedToToday: manuallyAddedToToday ?? this.manuallyAddedToToday,
      isStarred: isStarred ?? this.isStarred,
      reminder: reminder ?? this.reminder,
      repeatConfig: repeatConfig ?? this.repeatConfig,
      tags: tags ?? this.tags,
      steps: steps ?? this.steps,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (due.present) {
      map['due'] = Variable<String>(due.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (taskListId.present) {
      map['task_list_id'] = Variable<String>(taskListId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (manuallyAddedToToday.present) {
      map['manually_added_to_today'] = Variable<bool>(
        manuallyAddedToToday.value,
      );
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (reminder.present) {
      map['reminder'] = Variable<String>(reminder.value);
    }
    if (repeatConfig.present) {
      map['repeat_config'] = Variable<String>(repeatConfig.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (steps.present) {
      map['steps'] = Variable<String>(steps.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('due: $due, ')
          ..write('status: $status, ')
          ..write('updated: $updated, ')
          ..write('taskListId: $taskListId, ')
          ..write('parentId: $parentId, ')
          ..write('position: $position, ')
          ..write('manuallyAddedToToday: $manuallyAddedToToday, ')
          ..write('isStarred: $isStarred, ')
          ..write('reminder: $reminder, ')
          ..write('repeatConfig: $repeatConfig, ')
          ..write('tags: $tags, ')
          ..write('steps: $steps, ')
          ..write('completedAt: $completedAt, ')
          ..write('userId: $userId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskListsTable extends TaskLists
    with TableInfo<$TaskListsTable, TaskListEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    updated,
    syncStatus,
    isDefault,
    userId,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskListEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskListEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskListEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $TaskListsTable createAlias(String alias) {
    return $TaskListsTable(attachedDatabase, alias);
  }
}

class TaskListEntry extends DataClass implements Insertable<TaskListEntry> {
  /// Unique identifier
  final String id;

  /// Display title of the task list
  final String title;

  /// Last update timestamp as ISO8601 string
  final String updated;

  /// Sync status: 0=synced, 1=created, 2=updated, 3=deleted
  final int syncStatus;

  /// Whether this is the user's default task list
  final bool isDefault;

  /// Owning Supabase user id (for RLS), '' before auth is known.
  final String userId;

  /// Position within the sidebar for ordering
  final int position;
  const TaskListEntry({
    required this.id,
    required this.title,
    required this.updated,
    required this.syncStatus,
    required this.isDefault,
    required this.userId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['updated'] = Variable<String>(updated);
    map['sync_status'] = Variable<int>(syncStatus);
    map['is_default'] = Variable<bool>(isDefault);
    map['user_id'] = Variable<String>(userId);
    map['position'] = Variable<int>(position);
    return map;
  }

  TaskListsCompanion toCompanion(bool nullToAbsent) {
    return TaskListsCompanion(
      id: Value(id),
      title: Value(title),
      updated: Value(updated),
      syncStatus: Value(syncStatus),
      isDefault: Value(isDefault),
      userId: Value(userId),
      position: Value(position),
    );
  }

  factory TaskListEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskListEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      updated: serializer.fromJson<String>(json['updated']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      userId: serializer.fromJson<String>(json['userId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'updated': serializer.toJson<String>(updated),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'isDefault': serializer.toJson<bool>(isDefault),
      'userId': serializer.toJson<String>(userId),
      'position': serializer.toJson<int>(position),
    };
  }

  TaskListEntry copyWith({
    String? id,
    String? title,
    String? updated,
    int? syncStatus,
    bool? isDefault,
    String? userId,
    int? position,
  }) => TaskListEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    updated: updated ?? this.updated,
    syncStatus: syncStatus ?? this.syncStatus,
    isDefault: isDefault ?? this.isDefault,
    userId: userId ?? this.userId,
    position: position ?? this.position,
  );
  TaskListEntry copyWithCompanion(TaskListsCompanion data) {
    return TaskListEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      updated: data.updated.present ? data.updated.value : this.updated,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      userId: data.userId.present ? data.userId.value : this.userId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskListEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('updated: $updated, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDefault: $isDefault, ')
          ..write('userId: $userId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, updated, syncStatus, isDefault, userId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskListEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.updated == this.updated &&
          other.syncStatus == this.syncStatus &&
          other.isDefault == this.isDefault &&
          other.userId == this.userId &&
          other.position == this.position);
}

class TaskListsCompanion extends UpdateCompanion<TaskListEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> updated;
  final Value<int> syncStatus;
  final Value<bool> isDefault;
  final Value<String> userId;
  final Value<int> position;
  final Value<int> rowid;
  const TaskListsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.updated = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.userId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskListsCompanion.insert({
    required String id,
    required String title,
    required String updated,
    this.syncStatus = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.userId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       updated = Value(updated);
  static Insertable<TaskListEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? updated,
    Expression<int>? syncStatus,
    Expression<bool>? isDefault,
    Expression<String>? userId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (updated != null) 'updated': updated,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDefault != null) 'is_default': isDefault,
      if (userId != null) 'user_id': userId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskListsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? updated,
    Value<int>? syncStatus,
    Value<bool>? isDefault,
    Value<String>? userId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return TaskListsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      updated: updated ?? this.updated,
      syncStatus: syncStatus ?? this.syncStatus,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskListsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('updated: $updated, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDefault: $isDefault, ')
          ..write('userId: $userId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskListsTable taskLists = $TaskListsTable(this);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final TaskListDao taskListDao = TaskListDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tasks, taskLists];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      Value<String> title,
      Value<String> notes,
      Value<String?> due,
      Value<String> status,
      required String updated,
      required String taskListId,
      Value<String?> parentId,
      Value<double> position,
      Value<bool> manuallyAddedToToday,
      Value<bool> isStarred,
      Value<String?> reminder,
      Value<String?> repeatConfig,
      Value<String?> tags,
      Value<String?> steps,
      Value<String?> completedAt,
      Value<String> userId,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> notes,
      Value<String?> due,
      Value<String> status,
      Value<String> updated,
      Value<String> taskListId,
      Value<String?> parentId,
      Value<double> position,
      Value<bool> manuallyAddedToToday,
      Value<bool> isStarred,
      Value<String?> reminder,
      Value<String?> repeatConfig,
      Value<String?> tags,
      Value<String?> steps,
      Value<String?> completedAt,
      Value<String> userId,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskListId => $composableBuilder(
    column: $table.taskListId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manuallyAddedToToday => $composableBuilder(
    column: $table.manuallyAddedToToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminder => $composableBuilder(
    column: $table.reminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatConfig => $composableBuilder(
    column: $table.repeatConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskListId => $composableBuilder(
    column: $table.taskListId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manuallyAddedToToday => $composableBuilder(
    column: $table.manuallyAddedToToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminder => $composableBuilder(
    column: $table.reminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatConfig => $composableBuilder(
    column: $table.repeatConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<String> get taskListId => $composableBuilder(
    column: $table.taskListId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get manuallyAddedToToday => $composableBuilder(
    column: $table.manuallyAddedToToday,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<String> get reminder =>
      $composableBuilder(column: $table.reminder, builder: (column) => column);

  GeneratedColumn<String> get repeatConfig => $composableBuilder(
    column: $table.repeatConfig,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskEntry,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskEntry, BaseReferences<_$AppDatabase, $TasksTable, TaskEntry>),
          TaskEntry,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> due = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<String> taskListId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<bool> manuallyAddedToToday = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String?> reminder = const Value.absent(),
                Value<String?> repeatConfig = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> steps = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                notes: notes,
                due: due,
                status: status,
                updated: updated,
                taskListId: taskListId,
                parentId: parentId,
                position: position,
                manuallyAddedToToday: manuallyAddedToToday,
                isStarred: isStarred,
                reminder: reminder,
                repeatConfig: repeatConfig,
                tags: tags,
                steps: steps,
                completedAt: completedAt,
                userId: userId,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> due = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String updated,
                required String taskListId,
                Value<String?> parentId = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<bool> manuallyAddedToToday = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<String?> reminder = const Value.absent(),
                Value<String?> repeatConfig = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> steps = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                due: due,
                status: status,
                updated: updated,
                taskListId: taskListId,
                parentId: parentId,
                position: position,
                manuallyAddedToToday: manuallyAddedToToday,
                isStarred: isStarred,
                reminder: reminder,
                repeatConfig: repeatConfig,
                tags: tags,
                steps: steps,
                completedAt: completedAt,
                userId: userId,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskEntry,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskEntry, BaseReferences<_$AppDatabase, $TasksTable, TaskEntry>),
      TaskEntry,
      PrefetchHooks Function()
    >;
typedef $$TaskListsTableCreateCompanionBuilder =
    TaskListsCompanion Function({
      required String id,
      required String title,
      required String updated,
      Value<int> syncStatus,
      Value<bool> isDefault,
      Value<String> userId,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$TaskListsTableUpdateCompanionBuilder =
    TaskListsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> updated,
      Value<int> syncStatus,
      Value<bool> isDefault,
      Value<String> userId,
      Value<int> position,
      Value<int> rowid,
    });

class $$TaskListsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskListsTable> {
  $$TaskListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskListsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskListsTable> {
  $$TaskListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskListsTable> {
  $$TaskListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$TaskListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskListsTable,
          TaskListEntry,
          $$TaskListsTableFilterComposer,
          $$TaskListsTableOrderingComposer,
          $$TaskListsTableAnnotationComposer,
          $$TaskListsTableCreateCompanionBuilder,
          $$TaskListsTableUpdateCompanionBuilder,
          (
            TaskListEntry,
            BaseReferences<_$AppDatabase, $TaskListsTable, TaskListEntry>,
          ),
          TaskListEntry,
          PrefetchHooks Function()
        > {
  $$TaskListsTableTableManager(_$AppDatabase db, $TaskListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskListsCompanion(
                id: id,
                title: title,
                updated: updated,
                syncStatus: syncStatus,
                isDefault: isDefault,
                userId: userId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String updated,
                Value<int> syncStatus = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskListsCompanion.insert(
                id: id,
                title: title,
                updated: updated,
                syncStatus: syncStatus,
                isDefault: isDefault,
                userId: userId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskListsTable,
      TaskListEntry,
      $$TaskListsTableFilterComposer,
      $$TaskListsTableOrderingComposer,
      $$TaskListsTableAnnotationComposer,
      $$TaskListsTableCreateCompanionBuilder,
      $$TaskListsTableUpdateCompanionBuilder,
      (
        TaskListEntry,
        BaseReferences<_$AppDatabase, $TaskListsTable, TaskListEntry>,
      ),
      TaskListEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskListsTableTableManager get taskLists =>
      $$TaskListsTableTableManager(_db, _db.taskLists);
}
