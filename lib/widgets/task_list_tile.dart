import 'package:flutter/material.dart';

import '../models/task_list.dart';

/// Tile widget for displaying a task list.
class TaskListTile extends StatelessWidget {
  const TaskListTile({super.key, required this.taskList, this.onTap});

  final TaskList taskList;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          taskList.isDefault ? Icons.star : Icons.list,
          color: taskList.isDefault ? colorScheme.primary : null,
        ),
        title: Text(
          taskList.title,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: taskList.isDefault ? FontWeight.w600 : null,
          ),
        ),
        subtitle: Text(
          _formatUpdatedDate(taskList.updated),
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatUpdatedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
