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
                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? AppColors.primary
                              : AppColors.textHint,
                          width: 2,
                        ),
                        boxShadow: task.isCompleted
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(140),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
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
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: task.isCompleted
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                            decoration:
                                task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.notes,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Due date chip
                  if (task.due != null) _DueDateChip(dueDate: task.due!),
                  // Star icon
                  if (task.isStarred) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Due date chip with color coding
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
    Color borderColor;
    Color textColor;

    if (isOverdue) {
      bgColor = AppColors.danger.withAlpha(31);
      borderColor = AppColors.danger;
      textColor = AppColors.danger;
    } else if (isToday) {
      bgColor = AppColors.primary.withAlpha(31);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    } else {
      bgColor = AppColors.glassWhite;
      borderColor = AppColors.glassBorder;
      textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withAlpha(128), width: 0.8),
      ),
      child: Text(
        _formatDate(dueDate),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          color: textColor,
          fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
        ),
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
    if (diff < 0) return '${-diff} days ago';
    return '${date.month}/${date.day}';
  }
}