import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

/// Right panel showing task details
class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    this.onClose,
    this.onTitleChanged,
    this.onToggleSubtask,
    this.onAddSubtask,
    this.onDeleteTask,
    this.onToggleMyDay,
    this.onSetReminder,
  });

  final Task task;
  final VoidCallback? onClose;
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<int>? onToggleSubtask;
  final VoidCallback? onAddSubtask;
  final VoidCallback? onDeleteTask;
  final VoidCallback? onToggleMyDay;
  final VoidCallback? onSetReminder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(128),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDeleteTask,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Task title
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title (editable)
                  TextFormField(
                    initialValue: task.title,
                    onChanged: onTitleChanged,
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Task title',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtasks section
                  _buildSubtasksSection(context),
                  const SizedBox(height: 24),

                  // Add to My Day button
                  _ActionButton(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Add to My Day',
                    onTap: onToggleMyDay,
                  ),
                  const SizedBox(height: 8),

                  // Remind me button
                  _ActionButton(
                    icon: Icons.notifications_outlined,
                    label: 'Remind me',
                    onTap: onSetReminder,
                  ),
                  const SizedBox(height: 8),

                  // Due date
                  _ActionButton(
                    icon: Icons.calendar_today_outlined,
                    label: task.due != null
                        ? 'Due ${DateFormat.MMMd().format(task.due!)}'
                        : 'Set due date',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // Bottom section with created date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(128),
                ),
              ),
            ),
            child: Text(
              'Created ${_formatDate(task.updated)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mock subtasks for demo (in real app, these would come from the task)
    final subtasks = [
      _SubtaskItem(title: 'Research requirements', isCompleted: true),
      _SubtaskItem(title: 'Design solution', isCompleted: true),
      _SubtaskItem(title: 'Implement feature', isCompleted: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtasks header
        Row(
          children: [
            Icon(
              Icons.check_box_outline_blank,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Steps',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${subtasks.where((s) => s.isCompleted).length} of ${subtasks.length}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Subtask list
        ...subtasks.asMap().entries.map((entry) {
          final index = entry.key;
          final subtask = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () => onToggleSubtask?.call(index),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: subtask.isCompleted,
                        onChanged: (_) => onToggleSubtask?.call(index),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: subtask.isCompleted
                              ? colorScheme.outline
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Add next step button
        TextButton.icon(
          onPressed: onAddSubtask,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Next step'),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return DateFormat.MMMd().format(date);
  }
}

class _SubtaskItem {
  const _SubtaskItem({required this.title, required this.isCompleted});

  final String title;
  final bool isCompleted;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
