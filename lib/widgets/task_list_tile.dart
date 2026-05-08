import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_list.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Tile widget for displaying a task list - glassmorphism style.
class TaskListTile extends StatelessWidget {
  const TaskListTile({super.key, required this.taskList, this.onTap});

  final TaskList taskList;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: Row(
        children: [
          // List icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: taskList.isDefault
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF312E81), Color(0xFF6366F1)],
                    )
                  : null,
              color: taskList.isDefault ? null : AppColors.glassWhite,
            ),
            child: Icon(
              taskList.isDefault ? Icons.star : Icons.list,
              size: 20,
              color: taskList.isDefault ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskList.title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: taskList.isDefault ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatUpdatedDate(taskList.updated),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // Chevron
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ],
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