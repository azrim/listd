import 'package:flutter/material.dart';

/// Main shell widget with three-panel layout: sidebar | task list | detail panel
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.sidebar,
    required this.taskList,
    required this.detailPanel,
    this.selectedTaskId,
    this.onTaskSelected,
  });

  final Widget sidebar;
  final Widget taskList;
  final Widget detailPanel;
  final String? selectedTaskId;
  final ValueChanged<String?>? onTaskSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar - 220px fixed
          SizedBox(width: 220, child: sidebar),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Main task list - flexible
          Expanded(child: taskList),
          // Detail panel - shown only when a task is selected
          if (selectedTaskId != null) ...[
            const VerticalDivider(width: 1),
            SizedBox(width: 320, child: detailPanel),
          ],
        ],
      ),
    );
  }
}
