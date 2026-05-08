import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_colors.dart';

/// Task detail panel - 3rd column in 3-column layout.
class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.listId,
    this.onClose,
    this.onDelete,
  });

  final Task task;
  final String listId;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  Timer? _notesDebounce;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes);
  }

  @override
  void didUpdateWidget(TaskDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _titleController.text = widget.task.title;
      _notesController.text = widget.task.notes;
    }
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Update task via TasksNotifier provider
  void _updateTask(Task updatedTask) {
    ref
        .read(tasksNotifierProvider(widget.listId).notifier)
        .updateTask(updatedTask);
  }

  /// Toggle task completion
  void _toggleComplete() {
    ref
        .read(tasksNotifierProvider(widget.listId).notifier)
        .toggleComplete(widget.task);
  }

  /// Toggle star/important
  void _toggleStar() {
    _updateTask(widget.task.copyWith(isStarred: !widget.task.isStarred));
  }

  void _onTitleChanged(String value) {
    _updateTask(widget.task.copyWith(title: value));
  }

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 800), () {
      _updateTask(widget.task.copyWith(notes: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1629),
        border: const Border(
          left: BorderSide(color: Color(0xFF5C6BC0), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 24),
                    _buildSubtasksSection(),
                    const SizedBox(height: 24),
                    _buildMetadataSection(),
                    const SizedBox(height: 24),
                    _buildTagsSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A2040), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF8C8A97)),
            onPressed: widget.onClose,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350)),
            onPressed: () {
              ref
                  .read(tasksNotifierProvider(widget.listId).notifier)
                  .deleteTask(widget.task.id);
              widget.onClose?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        // Checkbox
        GestureDetector(
          onTap: _toggleComplete,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.task.isCompleted
                  ? AppColors.primary
                  : Colors.transparent,
              border: Border.all(
                color: widget.task.isCompleted
                    ? AppColors.primary
                    : const Color(0xFF5C5C5C),
                width: 2,
              ),
              boxShadow: widget.task.isCompleted
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: widget.task.isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        // Title
        Expanded(
          child: TextField(
            controller: _titleController,
            onChanged: _onTitleChanged,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.task.isCompleted
                  ? AppColors.textHint
                  : AppColors.textPrimary,
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Task title',
              hintStyle: GoogleFonts.manrope(color: AppColors.textHint),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // Star
        IconButton(
          icon: Icon(
            widget.task.isStarred ? Icons.star : Icons.star_border,
            color: widget.task.isStarred
                ? Colors.amber
                : AppColors.textSecondary,
          ),
          onPressed: _toggleStar,
        ),
      ],
    );
  }

  Widget _buildSubtasksSection() {
    final steps = widget.task.steps;
    final completedCount = steps.where((s) => s.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(
              Icons.check_box_outlined,
              size: 18,
              color: Color(0xFF8C8A97),
            ),
            const SizedBox(width: 8),
            Text(
              'STEPS',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C8A97),
                letterSpacing: 1.2,
              ),
            ),
            if (steps.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '$completedCount/${steps.length}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Steps list
        ...steps.map(
          (step) => _StepItem(
            step: step,
            onToggle: () {
              final updatedSteps = widget.task.steps.map((s) {
                if (s.id == step.id) {
                  return s.copyWith(isCompleted: !s.isCompleted);
                }
                return s;
              }).toList();
              _updateTask(widget.task.copyWith(steps: updatedSteps));
            },
          ),
        ),
        // Add step button
        GestureDetector(
          onTap: () => _showAddStepDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF8C8A97)),
                const SizedBox(width: 8),
                Text(
                  'Add step',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF8C8A97),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddStepDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2040),
        title: Text(
          'Add step',
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Step description',
            hintStyle: GoogleFonts.manrope(color: AppColors.textHint),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Add', style: GoogleFonts.manrope()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newStep = TaskStep(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result,
      );
      final updatedSteps = [...widget.task.steps, newStep];
      _updateTask(widget.task.copyWith(steps: updatedSteps));
    }
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folder
        _MetadataRow(
          icon: Icons.folder_outlined,
          label: 'Folder',
          value: 'Tasks',
          onTap: () {},
        ),
        // Reminder
        _MetadataRow(
          icon: Icons.notifications_outlined,
          label: 'Remind me',
          value: widget.task.hasReminder
              ? _formatTime(widget.task.reminder!)
              : null,
          valueColor: AppColors.primary,
          onTap: () => _showReminderPicker(),
        ),
        // Due date
        _MetadataRow(
          icon: Icons.calendar_today_outlined,
          label: 'Due date',
          value: widget.task.hasDueDate
              ? _formatDate(widget.task.due!)
              : 'Add due date',
          onTap: () => _showDueDatePicker(),
        ),
        // Repeat
        _MetadataRow(
          icon: Icons.repeat,
          label: 'Repeat',
          value: widget.task.hasRepeat
              ? widget.task.repeat!.type.name
              : 'No repeat',
          onTap: () => _showRepeatPicker(),
        ),
      ],
    );
  }

  Future<void> _showReminderPicker() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.task.reminder ?? now),
    );
    if (picked != null) {
      final reminder = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      _updateTask(widget.task.copyWith(reminder: reminder));
    }
  }

  Future<void> _showDueDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.task.due ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      _updateTask(widget.task.copyWith(due: picked));
    }
  }

  void _showRepeatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2040),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Daily'),
            onTap: () {
              _updateTask(
                widget.task.copyWith(
                  repeat: const RepeatConfig(type: RepeatType.daily),
                ),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Weekly'),
            onTap: () {
              _updateTask(
                widget.task.copyWith(
                  repeat: const RepeatConfig(type: RepeatType.weekly),
                ),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Monthly'),
            onTap: () {
              _updateTask(
                widget.task.copyWith(
                  repeat: const RepeatConfig(type: RepeatType.monthly),
                ),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Never'),
            onTap: () {
              _updateTask(widget.task.copyWith(clearRepeat: true));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final tags = widget.task.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAGS',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8C8A97),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final updatedTags = tags
                            .where((t) => t != tag)
                            .toList();
                        _updateTask(widget.task.copyWith(tags: updatedTags));
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF8C8A97),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Add tag button
            GestureDetector(
              onTap: _showAddTagDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF5C5C5C)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: Color(0xFF8C8A97)),
                    const SizedBox(width: 4),
                    Text(
                      'Add tag',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF8C8A97),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddTagDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2040),
        title: Text(
          'Add tag',
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tag name',
            hintStyle: GoogleFonts.manrope(color: AppColors.textHint),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Add', style: GoogleFonts.manrope()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updatedTags = [...widget.task.tags, result];
      _updateTask(widget.task.copyWith(tags: updatedTags));
    }
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTES',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8C8A97),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2040),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _notesController,
            onChanged: _onNotesChanged,
            maxLines: null,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle: GoogleFonts.manrope(color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'Created ${_formatDate(widget.task.updated)}',
      style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textHint),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Step item in subtasks list
class _StepItem extends StatelessWidget {
  final TaskStep step;
  final VoidCallback onToggle;

  const _StepItem({required this.step, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: step.isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: step.isCompleted
                      ? AppColors.primary
                      : const Color(0xFF5C5C5C),
                  width: 1.5,
                ),
              ),
              child: step.isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: step.isCompleted
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                  decoration: step.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metadata row (icon + label + value)
class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _MetadataRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2040),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8C8A97)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: valueColor ?? AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}
