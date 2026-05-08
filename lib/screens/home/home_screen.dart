import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/task_lists_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../theme/app_colors.dart';
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
    final taskListsAsync = ref.read(taskListsStreamProvider);
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
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    // Auto-select first list when data loads
    taskListsAsync.whenData((taskLists) {
      if (taskLists.isNotEmpty && selectedListId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedTaskListIdProvider.notifier).state =
              taskLists.first.id;
        });
      }
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF060818), Color(0xFF0D1535), Color(0xFF162040)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            // Col 1: Sidebar (240px always visible)
            const SizedBox(width: 240, child: SidebarPanel()),
            // Vertical divider
            Container(width: 1, color: AppColors.glassBorderSubtle),

            // Col 2: Task list - shrinks when detail panel opens
            Expanded(
              flex: showDetailPanel ? 1 : 1,
              child: TaskListPanel(
                listId: selectedListId ?? SpecialListIds.tasks,
                listName: listName,
                onTaskSelected: (task) {
                  ref.read(selectedTaskIdProvider.notifier).state = task.id;
                },
              ),
            ),

            // Col 3: Task detail panel - AnimatedContainer slides in/out
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: showDetailPanel ? 320 : 0,
              child: showDetailPanel
                  ? ClipRect(
                      child: OverflowBox(
                        maxWidth: 320,
                        minWidth: 320,
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 320,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0A1020), Color(0xFF0D1535)],
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
      ),
    );
  }

  Task? _getTaskForDetail(String taskId, String listId) {
    final tasksAsync = ref.read(tasksStreamProvider(listId));
    return tasksAsync.whenOrNull(
      data: (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
    );
  }
}
