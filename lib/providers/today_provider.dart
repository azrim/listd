/// Smart-bucket providers for the Listd 2027 redesign.
///
/// Smart lists are **computed views**, not folders. Each provider
/// reads `allTasksProvider` and returns the filtered slice, leaving
/// the underlying `tasksNotifierProvider(listId)` to handle the per-
/// list slice for user-created lists.
///
/// See `listd_2027_ux_plan.md` §1 for the rule table.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import 'tasks_provider.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Returns `true` when [task] should appear in **Today** for [now].
///
/// Rule (UX plan §1): due today OR repeated today OR
/// `manuallyAddedToToday` is set. Completed tasks are excluded so the
/// canvas doesn't fill up with finished work as the day goes on; the
/// caller can still surface them via a filter toggle.
///
/// "Starred today" from the spec is intentionally not in this rule —
/// `Important` covers starred regardless of date, and we don't want a
/// permanent star to pin tasks to Today forever.
bool isInToday(Task task, DateTime now) {
  if (task.isCompleted) return false;
  if (task.due != null && _sameDay(task.due!, now)) return true;
  if (task.reminder != null && _sameDay(task.reminder!, now)) return true;
  if (task.manuallyAddedToToday) return true;
  return false;
}

/// Tasks that belong on the Today canvas right now.
final todayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allAsync = ref.watch(allTasksProvider);
  final now = DateTime.now();
  return allAsync.whenData(
    (tasks) =>
        tasks.where((t) => isInToday(t, now)).toList()
          ..sort(_byDueThenPosition),
  );
});

/// Inbox: tasks the user hasn't filed into a real list yet. We treat
/// the user's default list as the inbox — every fresh capture lands
/// here unless `taskListId` is explicitly set.
final inboxTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allAsync = ref.watch(allTasksProvider);
  final listsAsync = ref.watch(allTasksProvider); // unused but keeps deps clear
  // ignore: unused_local_variable
  final _ = listsAsync;
  return allAsync.whenData(
    (tasks) =>
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  (t.taskListId.isEmpty || t.taskListId == 'inbox'),
            )
            .toList()
          ..sort(_byDueThenPosition),
  );
});

/// Important: every starred non-completed task across every list.
final importantTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allAsync = ref.watch(allTasksProvider);
  return allAsync.whenData(
    (tasks) =>
        tasks.where((t) => t.isStarred && !t.isCompleted).toList()
          ..sort(_byDueThenPosition),
  );
});

/// Planned: anything with a due date or a reminder.
final plannedTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allAsync = ref.watch(allTasksProvider);
  return allAsync.whenData(
    (tasks) =>
        tasks
            .where(
              (t) => !t.isCompleted && (t.due != null || t.reminder != null),
            )
            .toList()
          ..sort(_byDueThenPosition),
  );
});

/// Tasks bucketed by which day in [start, start + 7) they live in.
/// Used by the calendar strip's density bars.
final tasksByDayProvider =
    Provider.family<AsyncValue<Map<DateTime, int>>, DateTime>((ref, start) {
      final allAsync = ref.watch(allTasksProvider);
      final startOfStart = DateTime(start.year, start.month, start.day);
      return allAsync.whenData((tasks) {
        final counts = <DateTime, int>{};
        for (var i = 0; i < 7; i++) {
          final day = startOfStart.add(Duration(days: i));
          counts[day] = 0;
        }
        for (final t in tasks) {
          if (t.isCompleted) continue;
          if (t.due == null) continue;
          final key = DateTime(t.due!.year, t.due!.month, t.due!.day);
          if (counts.containsKey(key)) {
            counts[key] = counts[key]! + 1;
          }
        }
        return counts;
      });
    });

int _byDueThenPosition(Task a, Task b) {
  // Tasks with a due date sort earliest first; the rest fall to the
  // bottom and sort by position (the user-controllable ordering).
  if (a.due != null && b.due != null) {
    final c = a.due!.compareTo(b.due!);
    if (c != 0) return c;
  } else if (a.due != null) {
    return -1;
  } else if (b.due != null) {
    return 1;
  }
  return a.position.compareTo(b.position);
}
