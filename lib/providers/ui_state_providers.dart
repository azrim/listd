import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Provider for selected task ID (to show in detail panel)
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Provider for view mode (grid vs list)
final taskViewModeProvider = StateProvider<TaskViewMode>((ref) => TaskViewMode.list);

/// View mode options for the task list
enum TaskViewMode { list, grid }
