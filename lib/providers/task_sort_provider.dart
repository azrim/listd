import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_sort_mode.dart';

/// SharedPreferences key for the persisted [TaskSortMode] choice.
const _kTaskSortModeKey = 'listd.taskSortMode';

/// App-wide task sort preference, persisted across launches.
///
/// Defaults to [TaskSortMode.manual] for zero behaviour change on
/// existing installs — the menu is opt-in. Hydrates from
/// SharedPreferences on first build; the new value is written back
/// asynchronously so the UI updates instantly.
class TaskSortModeNotifier extends StateNotifier<TaskSortMode> {
  TaskSortModeNotifier({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      super(TaskSortMode.manual) {
    _hydrate();
  }

  final SharedPreferencesAsync _prefs;

  Future<void> _hydrate() async {
    final raw = await _prefs.getString(_kTaskSortModeKey);
    if (!mounted) return;
    state = taskSortModeFromKey(raw);
  }

  /// Update the active sort mode. UI updates synchronously; the
  /// SharedPreferences write happens in the background.
  void setMode(TaskSortMode mode) {
    if (state == mode) return;
    state = mode;
    unawaited(_prefs.setString(_kTaskSortModeKey, mode.persistKey));
  }
}

/// Riverpod provider for the active task sort mode. Watch this in
/// task list panels; call `notifier.setMode(...)` from the menu.
final taskSortModeProvider =
    StateNotifierProvider<TaskSortModeNotifier, TaskSortMode>((ref) {
      return TaskSortModeNotifier();
    });
