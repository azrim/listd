/// Listd 2027 sort modes for the per-list task pane.
///
/// `manual` (the default) preserves the user-defined `position`
/// ordering — the no-regression mode. The other four are app-wide
/// preferences exposed via the list-header `⋯` menu.
enum TaskSortMode {
  /// Preserve the user-defined `position` ordering.
  manual,

  /// Sort by due date ascending (no due → bottom). Falls back to
  /// `position` for ties.
  dueDate,

  /// Newest first (`updated` descending). Falls back to `position`.
  dateAdded,

  /// Title ascending, case-insensitive. Falls back to `position`.
  alphabetical,

  /// Starred tasks first, then by `position` within each bucket.
  starredFirst,
}

/// Stable label for the `⋯` menu and tests.
extension TaskSortModeLabel on TaskSortMode {
  String get label => switch (this) {
    TaskSortMode.manual => 'Manual',
    TaskSortMode.dueDate => 'Due date',
    TaskSortMode.dateAdded => 'Date added',
    TaskSortMode.alphabetical => 'Alphabetical',
    TaskSortMode.starredFirst => 'Starred first',
  };

  /// Stable string used by SharedPreferences. Keep this list in sync
  /// with [TaskSortMode] — adding a new mode without updating this
  /// will silently fall back to `manual` on next app launch.
  String get persistKey => switch (this) {
    TaskSortMode.manual => 'manual',
    TaskSortMode.dueDate => 'dueDate',
    TaskSortMode.dateAdded => 'dateAdded',
    TaskSortMode.alphabetical => 'alphabetical',
    TaskSortMode.starredFirst => 'starredFirst',
  };
}

/// Decode a [TaskSortMode] persisted by [TaskSortModeLabel.persistKey].
/// Unknown / null values fall back to [TaskSortMode.manual].
TaskSortMode taskSortModeFromKey(String? key) {
  for (final m in TaskSortMode.values) {
    if (m.persistKey == key) return m;
  }
  return TaskSortMode.manual;
}
