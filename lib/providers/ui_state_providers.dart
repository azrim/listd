import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import 'tasks_provider.dart';

/// Provider for selected task list ID in sidebar
final selectedTaskListIdProvider = StateProvider<String?>((ref) => null);

/// Provider for selected task ID (to show in detail panel)
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Resolves the currently-selected task by id against `allTasksProvider`,
/// so the inspector pane stays in sync with edits regardless of whether
/// the user is on a real list or a synthetic one (`@my-day`, `@important`,
/// `@planned`, `@tasks`). Returns `null` while data is loading or when the
/// id no longer maps to a task.
final selectedTaskProvider = Provider<Task?>((ref) {
  final taskId = ref.watch(selectedTaskIdProvider);
  if (taskId == null) return null;
  final allAsync = ref.watch(allTasksProvider);
  return allAsync.whenOrNull(
    data: (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
  );
});

/// Provider for view mode (grid vs list)
final taskViewModeProvider = StateProvider<TaskViewMode>(
  (ref) => TaskViewMode.list,
);

/// View mode options for the task list
enum TaskViewMode { list, grid }

/// Special list IDs for built-in views
class SpecialListIds {
  static const String myDay = '@myday';
  static const String important = '@important';
  static const String planned = '@planned';
  static const String tasks = '@tasks';
}
