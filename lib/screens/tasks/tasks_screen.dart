import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_text_field.dart';

/// Screen displaying tasks within a task list with glassmorphism UI.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({
    super.key,
    required this.taskListId,
    required this.taskListTitle,
  });

  final String taskListId;
  final String taskListTitle;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksNotifierProvider(widget.taskListId));

    return Scaffold(
      body: Stack(
        children: [
          // gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF060818),
                  Color(0xFF0D1535),
                  Color(0xFF162040),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Custom glass app bar
          _buildGlassAppBar(context),
          // Content
          SafeArea(
            child: tasksAsync.when(
              data: (tasks) => _buildTaskList(tasks),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildError(error),
            ),
          ),
          // FAB
          Positioned(right: 24, bottom: 24, child: _buildFAB()),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.go('/'),
            ),
            title: Text(
              widget.taskListTitle,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: _refreshTasks,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // Filter for main tasks (not subtasks)
    final mainTasks = tasks.where((t) => t.parentId == null).toList();

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      color: AppColors.primary,
      backgroundColor: AppColors.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        itemCount: mainTasks.length,
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          return _TaskGlassTile(
                key: ValueKey(task.id),
                task: task,
                onToggle: () => _toggleTask(task),
                onDelete: () => _deleteTask(task),
              )
              .animate()
              .fadeIn(delay: (index * 50).ms, duration: 300.ms)
              .slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(31),
                ),
                child: const Icon(
                  Icons.task_alt_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks yet',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add a new task',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withAlpha(31),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load tasks',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _refreshTasks,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: Text(
                  'Retry',
                  style: GoogleFonts.inter(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddTaskBottomSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _refreshTasks() async {
    final notifier = ref.read(
      tasksNotifierProvider(widget.taskListId).notifier,
    );
    await notifier.refresh();
  }

  Future<void> _toggleTask(Task task) async {
    final notifier = ref.read(
      tasksNotifierProvider(widget.taskListId).notifier,
    );
    await notifier.toggleComplete(task);
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'Delete task',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        tasksNotifierProvider(widget.taskListId).notifier,
      );
      await notifier.deleteTask(task.id);
    }
  }

  Future<void> _showAddTaskBottomSheet() async {
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bgSurfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add Task',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FocusedGlassTextField(
                    controller: controller,
                    hint: 'Task title',
                    prefixIcon: Icons.add_task,
                    autofocus: true,
                    onSubmitted: (value) => _addTask(context, value),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _addTask(context, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Add Task',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addTask(BuildContext context, String title) async {
    if (title.trim().isEmpty) return;

    final notifier = ref.read(
      tasksNotifierProvider(widget.taskListId).notifier,
    );
    final newTask = Task(
      id: '',
      title: title.trim(),
      updated: DateTime.now(),
      taskListId: widget.taskListId,
    );
    await notifier.createTask(newTask);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Glass tile for task item with animated checkbox
class _TaskGlassTile extends StatelessWidget {
  const _TaskGlassTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onToggle;
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
        return false; // Let the callback handle it
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            // Animated checkbox
            _AnimatedCheckbox(isCompleted: task.isCompleted, onTap: onToggle),
            const SizedBox(width: 14),
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
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
                  if (task.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes,
                      style: GoogleFonts.inter(
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
              const Icon(Icons.star, size: 18, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated checkbox with glow effect
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
              width: 26,
              height: 26,
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
        style: GoogleFonts.inter(
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
