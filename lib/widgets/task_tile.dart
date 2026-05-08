import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.glassBorder.withAlpha(64),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Animated checkbox
                  _AnimatedCheckbox(
                    isCompleted: task.isCompleted,
                    onTap: onToggle,
                  ),
                  const SizedBox(width: 14),
                  // Task content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          task.title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: task.isCompleted
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        // Metadata chips (only show if any exist)
                        if (task.hasDueDate ||
                            task.hasRepeat ||
                            task.hasReminder ||
                            task.tags.isNotEmpty ||
                            task.hasNotes ||
                            task.steps.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _MetadataChips(task: task),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Star icon
                  if (task.isStarred)
                    const Icon(Icons.star, size: 20, color: Colors.amber),
                ],
              ),
            ),
          ),
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

    // Due date chip
    if (task.hasDueDate) {
      chips.add(_DueDateChip(dueDate: task.due!));
    }

    // Repeat chip
    if (task.hasRepeat) {
      chips.add(_RepeatChip(repeat: task.repeat!));
    }

    // Reminder chip
    if (task.hasReminder) {
      chips.add(_ReminderChip(reminder: task.reminder!));
    }

    // Tags chip (first tag + count if more)
    if (task.tags.isNotEmpty) {
      chips.add(_TagsChip(tags: task.tags));
    }

    // Notes indicator
    if (task.hasNotes) {
      chips.add(_NotesIndicator());
    }

    // Steps progress
    if (task.steps.isNotEmpty) {
      chips.add(_StepsProgress(steps: task.steps));
    }

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

/// Animated circular checkbox.
class _AnimatedCheckbox extends StatefulWidget {
  const _AnimatedCheckbox({required this.isCompleted, this.onTap});

  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _controller.forward().then((_) => _controller.reverse());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: widget.isCompleted
                      ? AppColors.primary
                      : AppColors.textHint,
                  width: 2,
                ),
                boxShadow: widget.isCompleted
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(140),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: widget.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
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
            style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
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
          Text(
            _formatReminder(reminder),
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatReminder(DateTime reminder) {
    final now = DateTime.now();
    final diff = reminder.difference(now);

    if (diff.isNegative) return 'Overdue';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${reminder.month}/${reminder.day}';
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
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notes indicator dot.
class _NotesIndicator extends StatelessWidget {
  const _NotesIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
    );
  }
}

/// Steps progress indicator.
class _StepsProgress extends StatelessWidget {
  const _StepsProgress({required this.steps});

  final List<TaskStep> steps;

  @override
  Widget build(BuildContext context) {
    final completed = steps.where((s) => s.isCompleted).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_box_outlined,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '$completed/${steps.length} steps',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
