import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../widgets/sidebar_panel.dart';
import '../../widgets/task_list_panel.dart';
import '../../widgets/task_detail_panel.dart';

/// Home screen with adaptive 2→3 column layout:
///
/// Default (2 columns):
///   Col 1: Sidebar (240px fixed)
///   Col 2: Task list (fills remaining space with Expanded)
///
/// When task selected (3 columns):
///   Col 1: Sidebar (240px fixed, unchanged)
///   Col 2: Task list (shrinks - no longer Expanded, gets min width)
///   Col 3: Task detail panel (320px, slides in from right)
///
/// Tapping a task: sets selectedTask → panel slides in
/// Tapping X or Escape: clears selectedTask → panel slides out
/// Tapping different task: swaps content in open panel (no close/reopen)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectFirstList();
    });
  }

  void _selectFirstList() {
    final taskListsAsync = ref.read(taskListsNotifierProvider);
    taskListsAsync.whenData((taskLists) {
      if (taskLists.isNotEmpty) {
        final currentSelection = ref.read(selectedTaskListIdProvider);
        if (currentSelection == null) {
          ref.read(selectedTaskListIdProvider.notifier).state =
              taskLists.first.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    final taskListsAsync = ref.watch(taskListsNotifierProvider);

    // Listen for the first non-empty data load and auto-select the first list
    // (no postFrame; ref.listen runs after the build completes).
    ref.listen<AsyncValue<List<TaskList>>>(taskListsNotifierProvider, (
      previous,
      next,
    ) {
      next.whenData((taskLists) {
        if (taskLists.isEmpty) return;
        if (ref.read(selectedTaskListIdProvider) != null) return;
        ref.read(selectedTaskListIdProvider.notifier).state =
            taskLists.first.id;
      });
    });

    // Get list name
    String listName = 'Tasks';
    if (selectedListId != null && !selectedListId.startsWith('@')) {
      listName = taskListsAsync.when(
        data: (taskLists) {
          final found = taskLists
              .where((tl) => tl.id == selectedListId)
              .firstOrNull;
          return found?.title ?? 'Tasks';
        },
        loading: () => 'Loading...',
        error: (_, _) => 'Tasks',
      );
    } else if (selectedListId != null) {
      listName = switch (selectedListId) {
        SpecialListIds.myDay => 'My Day',
        SpecialListIds.important => 'Important',
        SpecialListIds.planned => 'Planned',
        SpecialListIds.tasks => 'Tasks',
        _ => 'Tasks',
      };
    }

    // Get selected task for detail panel
    final selectedTask = selectedTaskId != null
        ? _getTaskForDetail(
            selectedTaskId,
            selectedListId ?? SpecialListIds.tasks,
          )
        : null;

    // Check if detail panel should be shown
    final showDetailPanel = selectedTask != null;

    final scheme = Theme.of(context).colorScheme;
    final detailPanelBg = scheme.surfaceContainerLow;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Row(
        children: [
          // Col 1: Sidebar (264px per Stitch design)
          const SizedBox(width: 264, child: SidebarPanel()),
          Container(width: 1, color: scheme.outlineVariant),

          // Col 2: Task list - shrinks when detail panel opens
          Expanded(
            child: TaskListPanel(
              listId: selectedListId ?? SpecialListIds.tasks,
              listName: listName,
              onTaskSelected: (task) {
                ref.read(selectedTaskIdProvider.notifier).state = task.id;
              },
            ),
          ),

          // Col 3: Task detail panel - AnimatedContainer slides in/out (360px per Stitch design)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: showDetailPanel ? 360 : 0,
            child: showDetailPanel
                ? ClipRect(
                    child: OverflowBox(
                      maxWidth: 360,
                      minWidth: 360,
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 360,
                        decoration: BoxDecoration(
                          color: detailPanelBg,
                          border: Border(
                            left: BorderSide(
                              color: scheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                        ),
                        child: TaskDetailPanel(
                          task: selectedTask,
                          listId: selectedListId ?? SpecialListIds.tasks,
                          onClose: () {
                            ref.read(selectedTaskIdProvider.notifier).state =
                                null;
                          },
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Task? _getTaskForDetail(String taskId, String listId) {
    final tasksAsync = ref.read(tasksNotifierProvider(listId));
    return tasksAsync.whenOrNull(
      data: (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
    );
  }
}
