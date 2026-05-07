import 'package:flutter/material.dart';

import '../models/task.dart';

/// Tile widget for displaying a task with checkbox and actions.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle?.call(),
        ),
        title: Text(
          task.title,
          style: textTheme.bodyLarge?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? colorScheme.outline : null,
          ),
        ),
        subtitle: task.due != null
            ? Text(
                _formatDueDate(task.due!),
                style: textTheme.bodySmall?.copyWith(
                  color: _getDueDateColor(context, task.due!),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final difference = dueDay.difference(today).inDays;

    if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference == -1) {
      return 'Overdue by 1 day';
    } else if (difference < 0) {
      return 'Overdue by ${-difference} days';
    } else if (difference < 7) {
      return 'Due in $difference days';
    } else {
      return 'Due ${date.day}/${date.month}';
    }
  }

  Color _getDueDateColor(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final difference = dueDay.difference(today).inDays;

    final colorScheme = Theme.of(context).colorScheme;

    if (difference < 0) {
      return colorScheme.error;
    } else if (difference == 0) {
      return colorScheme.primary;
    } else if (difference <= 2) {
      return Colors.orange;
    }
    return colorScheme.outline;
  }
}
