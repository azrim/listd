import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/task_lists_provider.dart';
import '../../widgets/sidebar_panel.dart';
import '../../widgets/task_list_panel.dart';

/// Home screen with Microsoft To-Do style three-panel layout
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    // Get the list name based on selection
    String listName;
    if (selectedListId == null) {
      listName = 'Tasks';
    } else if (selectedListId.startsWith('@')) {
      // Special list
      switch (selectedListId) {
        case SpecialListIds.myDay:
          listName = 'My Day';
          break;
        case SpecialListIds.important:
          listName = 'Important';
          break;
        case SpecialListIds.planned:
          listName = 'Planned';
          break;
        case SpecialListIds.tasks:
        default:
          listName = 'Tasks';
      }
    } else {
      // Google Task list - find the title from task lists
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
    }

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar - 220px fixed
          const SizedBox(width: 220, child: SidebarPanel()),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Main task list panel (flexible)
          Expanded(
            child: TaskListPanel(
              listId: selectedListId ?? SpecialListIds.tasks,
              listName: listName,
            ),
          ),
        ],
      ),
    );
  }
}
