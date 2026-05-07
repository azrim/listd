import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/sidebar_panel.dart';
import '../../widgets/task_list_panel.dart';

/// Home screen with Microsoft To-Do style three-panel layout
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);

    // Get the list name
    String listName;
    switch (selectedListId) {
      case 'myday':
        listName = 'My Day';
        break;
      case 'important':
        listName = 'Important';
        break;
      case 'planned':
        listName = 'Planned';
        break;
      case 'shopping':
        listName = 'Shopping';
        break;
      case 'work':
        listName = 'Work';
        break;
      default:
        listName = 'Tasks';
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
              listId: selectedListId ?? 'default',
              listName: listName,
            ),
          ),
        ],
      ),
    );
  }
}
