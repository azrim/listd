import 'package:flutter_test/flutter_test.dart';

import 'package:listd/models/task.dart';
import 'package:listd/models/task_sort_mode.dart';

/// Pins the [Task.compareBy] comparator semantics for the user-pickable
/// sort modes plus the implicit "completed-to-bottom" rule applied at
/// the call site (`task_list_panel.dart#_buildContent`).
void main() {
  Task make({
    required String id,
    required String title,
    DateTime? due,
    DateTime? updated,
    bool starred = false,
    bool completed = false,
    double position = 0,
  }) {
    return Task(
      id: id,
      title: title,
      due: due,
      status: completed ? 'completed' : 'needsAction',
      isStarred: starred,
      position: position,
      updated: updated ?? DateTime(2025),
      taskListId: 'l1',
    );
  }

  group('TaskSortMode.manual', () {
    test('preserves position order', () {
      final tasks = <Task>[
        make(id: 'a', title: 'A', position: 200),
        make(id: 'b', title: 'B', position: 100),
        make(id: 'c', title: 'C', position: 300),
      ]..sort((a, b) => Task.compareBy(a, b, TaskSortMode.manual));
      expect(tasks.map((t) => t.id), ['b', 'a', 'c']);
    });
  });

  group('TaskSortMode.dueDate', () {
    test('puts no-due tasks at the bottom and ties break on position', () {
      final tasks = <Task>[
        make(id: 'late', title: 'late', due: DateTime(2025, 6, 1), position: 1),
        make(id: 'none', title: 'none', position: 2),
        make(
          id: 'early',
          title: 'early',
          due: DateTime(2025, 1, 1),
          position: 3,
        ),
        make(id: 'tieA', title: 'tieA', due: DateTime(2025, 1, 1), position: 4),
      ]..sort((a, b) => Task.compareBy(a, b, TaskSortMode.dueDate));
      expect(tasks.map((t) => t.id), ['early', 'tieA', 'late', 'none']);
    });
  });

  group('TaskSortMode.dateAdded', () {
    test('newest first by `updated`', () {
      final tasks = <Task>[
        make(id: 'old', title: 'old', updated: DateTime(2024)),
        make(id: 'new', title: 'new', updated: DateTime(2026)),
        make(id: 'mid', title: 'mid', updated: DateTime(2025)),
      ]..sort((a, b) => Task.compareBy(a, b, TaskSortMode.dateAdded));
      expect(tasks.map((t) => t.id), ['new', 'mid', 'old']);
    });
  });

  group('TaskSortMode.alphabetical', () {
    test('case-insensitive title order, ties → position', () {
      final tasks = <Task>[
        make(id: 'z', title: 'Zebra', position: 3),
        make(id: 'b', title: 'banana', position: 2),
        make(id: 'a', title: 'apple', position: 1),
        make(id: 'a2', title: 'Apple', position: 4),
      ]..sort((a, b) => Task.compareBy(a, b, TaskSortMode.alphabetical));
      expect(tasks.map((t) => t.id), ['a', 'a2', 'b', 'z']);
    });
  });

  group('TaskSortMode.starredFirst', () {
    test('starred bucket first, ties break on position within bucket', () {
      final tasks = <Task>[
        make(id: 'p1', title: 'p1', position: 1),
        make(id: 's2', title: 's2', starred: true, position: 4),
        make(id: 'p2', title: 'p2', position: 2),
        make(id: 's1', title: 's1', starred: true, position: 3),
      ]..sort((a, b) => Task.compareBy(a, b, TaskSortMode.starredFirst));
      expect(tasks.map((t) => t.id), ['s1', 's2', 'p1', 'p2']);
    });
  });

  group('completed-to-bottom rule', () {
    /// Mirrors the comparator the panel applies in `_buildContent`:
    /// completed tasks always sink past active ones, regardless of
    /// the chosen sort mode. The mode only orders within each bucket.
    int compare(Task a, Task b, TaskSortMode mode) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return Task.compareBy(a, b, mode);
    }

    test('sinks completed past active even for due-date sort', () {
      final tasks = <Task>[
        make(
          id: 'doneEarly',
          title: 'doneEarly',
          due: DateTime(2024, 1, 1),
          completed: true,
          position: 1,
        ),
        make(id: 'open', title: 'open', due: DateTime(2025, 6, 1), position: 2),
        make(
          id: 'doneLate',
          title: 'doneLate',
          due: DateTime(2026, 1, 1),
          completed: true,
          position: 3,
        ),
      ]..sort((a, b) => compare(a, b, TaskSortMode.dueDate));
      expect(tasks.map((t) => t.id), ['open', 'doneEarly', 'doneLate']);
    });

    test('within completed bucket the chosen mode still orders', () {
      final tasks = <Task>[
        make(
          id: 'doneB',
          title: 'doneB',
          completed: true,
          updated: DateTime(2024),
        ),
        make(
          id: 'doneA',
          title: 'doneA',
          completed: true,
          updated: DateTime(2026),
        ),
        make(id: 'open', title: 'open', updated: DateTime(2023)),
      ]..sort((a, b) => compare(a, b, TaskSortMode.dateAdded));
      expect(tasks.map((t) => t.id), ['open', 'doneA', 'doneB']);
    });
  });
}
