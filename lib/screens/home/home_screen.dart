import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/task_lists_provider.dart';
import '../../widgets/sidebar_panel.dart';
import '../../widgets/task_list_panel.dart';

/// Home screen with Microsoft To-Do style three-panel layout
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-select first list when data loads
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

    // Get the list name
    String listName;
    if (selectedListId == null || selectedListId.startsWith('@')) {
      listName = selectedListId == SpecialListIds.myDay
          ? 'My Day'
          : selectedListId == SpecialListIds.important
          ? 'Important'
          : selectedListId == SpecialListIds.planned
          ? 'Planned'
          : 'Tasks';
    } else {
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
          // Main task list panel
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
