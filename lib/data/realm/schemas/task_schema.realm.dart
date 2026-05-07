// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class TaskSchema extends _TaskSchema
    with RealmEntity, RealmObjectBase, RealmObject {
  TaskSchema(
    ObjectId id,
    String title,
    String notes,
    bool isCompleted,
    bool isImportant,
    bool isMyDay,
    String taskListId,
    String parentId,
    int position,
    DateTime createdAt,
    DateTime updatedAt,
    bool isDeleted, {
    DateTime? due,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'notes', notes);
    RealmObjectBase.set(this, 'due', due);
    RealmObjectBase.set(this, 'isCompleted', isCompleted);
    RealmObjectBase.set(this, 'isImportant', isImportant);
    RealmObjectBase.set(this, 'isMyDay', isMyDay);
    RealmObjectBase.set(this, 'taskListId', taskListId);
    RealmObjectBase.set(this, 'parentId', parentId);
    RealmObjectBase.set(this, 'position', position);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'isDeleted', isDeleted);
  }

  TaskSchema._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  String get notes => RealmObjectBase.get<String>(this, 'notes') as String;
  @override
  set notes(String value) => RealmObjectBase.set(this, 'notes', value);

  @override
  DateTime? get due => RealmObjectBase.get<DateTime>(this, 'due') as DateTime?;
  @override
  set due(DateTime? value) => RealmObjectBase.set(this, 'due', value);

  @override
  bool get isCompleted =>
      RealmObjectBase.get<bool>(this, 'isCompleted') as bool;
  @override
  set isCompleted(bool value) =>
      RealmObjectBase.set(this, 'isCompleted', value);

  @override
  bool get isImportant =>
      RealmObjectBase.get<bool>(this, 'isImportant') as bool;
  @override
  set isImportant(bool value) =>
      RealmObjectBase.set(this, 'isImportant', value);

  @override
  bool get isMyDay => RealmObjectBase.get<bool>(this, 'isMyDay') as bool;
  @override
  set isMyDay(bool value) => RealmObjectBase.set(this, 'isMyDay', value);

  @override
  String get taskListId =>
      RealmObjectBase.get<String>(this, 'taskListId') as String;
  @override
  set taskListId(String value) =>
      RealmObjectBase.set(this, 'taskListId', value);

  @override
  String get parentId =>
      RealmObjectBase.get<String>(this, 'parentId') as String;
  @override
  set parentId(String value) => RealmObjectBase.set(this, 'parentId', value);

  @override
  int get position => RealmObjectBase.get<int>(this, 'position') as int;
  @override
  set position(int value) => RealmObjectBase.set(this, 'position', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  DateTime get updatedAt =>
      RealmObjectBase.get<DateTime>(this, 'updatedAt') as DateTime;
  @override
  set updatedAt(DateTime value) =>
      RealmObjectBase.set(this, 'updatedAt', value);

  @override
  bool get isDeleted => RealmObjectBase.get<bool>(this, 'isDeleted') as bool;
  @override
  set isDeleted(bool value) => RealmObjectBase.set(this, 'isDeleted', value);

  @override
  Stream<RealmObjectChanges<TaskSchema>> get changes =>
      RealmObjectBase.getChanges<TaskSchema>(this);

  @override
  Stream<RealmObjectChanges<TaskSchema>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<TaskSchema>(this, keyPaths);

  @override
  TaskSchema freeze() => RealmObjectBase.freezeObject<TaskSchema>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'notes': notes.toEJson(),
      'due': due.toEJson(),
      'isCompleted': isCompleted.toEJson(),
      'isImportant': isImportant.toEJson(),
      'isMyDay': isMyDay.toEJson(),
      'taskListId': taskListId.toEJson(),
      'parentId': parentId.toEJson(),
      'position': position.toEJson(),
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'isDeleted': isDeleted.toEJson(),
    };
  }

  static EJsonValue _toEJson(TaskSchema value) => value.toEJson();
  static TaskSchema _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
        'notes': EJsonValue notes,
        'isCompleted': EJsonValue isCompleted,
        'isImportant': EJsonValue isImportant,
        'isMyDay': EJsonValue isMyDay,
        'taskListId': EJsonValue taskListId,
        'parentId': EJsonValue parentId,
        'position': EJsonValue position,
        'createdAt': EJsonValue createdAt,
        'updatedAt': EJsonValue updatedAt,
        'isDeleted': EJsonValue isDeleted,
      } =>
        TaskSchema(
          fromEJson(id),
          fromEJson(title),
          fromEJson(notes),
          fromEJson(isCompleted),
          fromEJson(isImportant),
          fromEJson(isMyDay),
          fromEJson(taskListId),
          fromEJson(parentId),
          fromEJson(position),
          fromEJson(createdAt),
          fromEJson(updatedAt),
          fromEJson(isDeleted),
          due: fromEJson(ejson['due']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(TaskSchema._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      TaskSchema,
      'TaskSchema',
      [
        SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
        SchemaProperty('title', RealmPropertyType.string),
        SchemaProperty('notes', RealmPropertyType.string),
        SchemaProperty('due', RealmPropertyType.timestamp, optional: true),
        SchemaProperty('isCompleted', RealmPropertyType.bool),
        SchemaProperty('isImportant', RealmPropertyType.bool),
        SchemaProperty('isMyDay', RealmPropertyType.bool),
        SchemaProperty('taskListId', RealmPropertyType.string),
        SchemaProperty('parentId', RealmPropertyType.string),
        SchemaProperty('position', RealmPropertyType.int),
        SchemaProperty('createdAt', RealmPropertyType.timestamp),
        SchemaProperty('updatedAt', RealmPropertyType.timestamp),
        SchemaProperty('isDeleted', RealmPropertyType.bool),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
