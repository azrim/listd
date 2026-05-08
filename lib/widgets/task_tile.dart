import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Glassmorphism tile widget for displaying a task with checkbox and actions.
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
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: AppColors.danger),
      ),
      confirmDismiss: (direction) async {
        onDelete?.call();
        return false;
      },
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => onToggle?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? AppColors.primary
                        : Colors.white38,
                    width: 2,
                  ),
                  boxShadow: task.isCompleted
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? Colors.white.withOpacity(0.38)
                          : Colors.white.withOpacity(0.92),
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      fontSize: 15,
                    ),
                  ),
                  // Notes preview if exists
                  if (task.hasNotes) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Metadata chips
                  if (task.hasDueDate ||
                      task.hasRepeat ||
                      task.hasReminder ||
                      task.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _MetadataChips(task: task),
                  ],
                ],
              ),
            ),
            // Due date chip
            if (task.hasDueDate) _DueDateChip(dueDate: task.due!),
            // Star icon
            if (task.isStarred) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 20, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }
}

/// Metadata chips row showing due date, repeat, tags, notes indicator, steps progress.
class _MetadataChips extends StatelessWidget {
  const _MetadataChips({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (task.hasDueDate) chips.add(_DueDateChip(dueDate: task.due!));
    if (task.hasRepeat) chips.add(_RepeatChip(repeat: task.repeat!));
    if (task.hasReminder) chips.add(_ReminderChip(reminder: task.reminder!));
    if (task.tags.isNotEmpty) chips.add(_TagsChip(tags: task.tags));

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

/// Due date chip with color coding.
class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueDay.difference(today).inDays;

    final isOverdue = diff < 0;
    final isToday = diff == 0;

    Color bgColor;
    Color textColor;

    if (isOverdue) {
      bgColor = AppColors.danger.withAlpha(31);
      textColor = AppColors.danger;
    } else {
      bgColor = AppColors.primary.withAlpha(31);
      textColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            _formatDate(dueDate),
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    if (diff < 0) return '${-diff}d ago';
    return '${date.month}/${date.day}';
  }
}

/// Repeat chip showing repeat type.
class _RepeatChip extends StatelessWidget {
  const _RepeatChip({required this.repeat});

  final RepeatConfig repeat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            _formatRepeat(repeat),
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatRepeat(RepeatConfig config) {
    switch (config.type) {
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return config.interval == 1
            ? 'Weekly'
            : 'Every ${config.interval} weeks';
      case RepeatType.monthly:
        return config.interval == 1
            ? 'Monthly'
            : 'Every ${config.interval} months';
      case RepeatType.yearly:
        return config.interval == 1
            ? 'Yearly'
            : 'Every ${config.interval} years';
      case RepeatType.custom:
        return 'Custom';
    }
  }
}

/// Reminder chip showing time until reminder.
class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.reminder});

  final DateTime reminder;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = reminder.difference(now);

    String label;
    if (diff.isNegative) {
      label = 'Overdue';
    } else if (diff.inMinutes < 60) {
      label = '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      label = '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      label = '${diff.inDays}d';
    } else {
      label = '${reminder.month}/${reminder.day}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.primary)),
        ],
      ),
    );
  }
}

/// Tags chip showing first tag and count.
class _TagsChip extends StatelessWidget {
  const _TagsChip({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final displayTag = tags.first;
    final remainingCount = tags.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            remainingCount > 0 ? '$displayTag +$remainingCount' : displayTag,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
