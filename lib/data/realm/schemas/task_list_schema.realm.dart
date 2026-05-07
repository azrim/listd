// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class TaskListSchema extends _TaskListSchema
    with RealmEntity, RealmObjectBase, RealmObject {
  TaskListSchema(
    ObjectId id,
    String title,
    bool isDefault,
    int position,
    DateTime createdAt,
    DateTime updatedAt,
    bool isDeleted,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'isDefault', isDefault);
    RealmObjectBase.set(this, 'position', position);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'isDeleted', isDeleted);
  }

  TaskListSchema._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  bool get isDefault => RealmObjectBase.get<bool>(this, 'isDefault') as bool;
  @override
  set isDefault(bool value) => RealmObjectBase.set(this, 'isDefault', value);

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
  Stream<RealmObjectChanges<TaskListSchema>> get changes =>
      RealmObjectBase.getChanges<TaskListSchema>(this);

  @override
  Stream<RealmObjectChanges<TaskListSchema>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<TaskListSchema>(this, keyPaths);

  @override
  TaskListSchema freeze() => RealmObjectBase.freezeObject<TaskListSchema>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'isDefault': isDefault.toEJson(),
      'position': position.toEJson(),
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'isDeleted': isDeleted.toEJson(),
    };
  }

  static EJsonValue _toEJson(TaskListSchema value) => value.toEJson();
  static TaskListSchema _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
        'isDefault': EJsonValue isDefault,
        'position': EJsonValue position,
        'createdAt': EJsonValue createdAt,
        'updatedAt': EJsonValue updatedAt,
        'isDeleted': EJsonValue isDeleted,
      } =>
        TaskListSchema(
          fromEJson(id),
          fromEJson(title),
          fromEJson(isDefault),
          fromEJson(position),
          fromEJson(createdAt),
          fromEJson(updatedAt),
          fromEJson(isDeleted),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(TaskListSchema._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      TaskListSchema,
      'TaskListSchema',
      [
        SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
        SchemaProperty('title', RealmPropertyType.string),
        SchemaProperty('isDefault', RealmPropertyType.bool),
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
