import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: surfaces?.detailPanel ?? scheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 24),
                    _buildMetadataSection(),
                    const SizedBox(height: 24),
                    _buildSubtasksSection(),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          _QuietIconButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: widget.onClose,
          ),
          const Spacer(),
          _QuietIconButton(
            icon: Icons.delete_outline,
            color: scheme.error,
            tooltip: 'Delete task',
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _toggleComplete,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.task.isCompleted
                  ? scheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: widget.task.isCompleted
                    ? scheme.primary
                    : scheme.outline,
                width: 1.5,
              ),
            ),
            child: widget.task.isCompleted
                ? Icon(Icons.check, size: 12, color: scheme.onPrimary)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _titleController,
            onChanged: _onTitleChanged,
            style: GoogleFonts.inter(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.22,
              color: widget.task.isCompleted
                  ? scheme.outline
                  : scheme.onSurface,
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: scheme.outline,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: 'Task title',
              hintStyle: GoogleFonts.inter(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.22,
                color: scheme.outline,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 4),
        _QuietIconButton(
          icon: widget.task.isStarred ? Icons.star : Icons.star_border,
          tooltip: widget.task.isStarred ? 'Unstar' : 'Star',
          color: widget.task.isStarred
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
          onPressed: _toggleStar,
        ),
      ],
    );
  }

  Widget _buildSubtasksSection() {
    final scheme = Theme.of(context).colorScheme;
    final steps = widget.task.steps;
    final completedCount = steps.where((s) => s.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('STEPS', style: _captionStyle(scheme)),
            if (steps.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '$completedCount of ${steps.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 16 / 11,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
        InkWell(
          onTap: () => _showAddStepDialog(),
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.add, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Add step',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
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
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Add step',
            style: GoogleFonts.inter(color: scheme.onSurface),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Step description',
              hintStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: scheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Add', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
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
    final scheme = Theme.of(context).colorScheme;
    final lists =
        ref.watch(taskListsNotifierProvider).valueOrNull ?? const <TaskList>[];
    final owningList = lists
        .where((l) => l.id == widget.task.taskListId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folder
        _MetadataRow(
          icon: Icons.folder_outlined,
          label: 'Folder',
          value: owningList?.title ?? 'Tasks',
          onTap: () => _showFolderPicker(lists, owningList),
        ),
        // Reminder
        _MetadataRow(
          icon: Icons.notifications_outlined,
          label: 'Remind me',
          value: widget.task.hasReminder
              ? _formatTime(widget.task.reminder!)
              : null,
          valueColor: scheme.primary,
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

  Future<void> _showFolderPicker(
    List<TaskList> lists,
    TaskList? current,
  ) async {
    if (lists.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Create a folder first')));
      return;
    }
    final picked = await showModalBottomSheet<TaskList>(
      context: context,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Move to folder',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              for (final list in lists)
                ListTile(
                  leading: Icon(
                    Icons.folder_outlined,
                    color: list.id == current?.id
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  title: Text(list.title),
                  trailing: list.id == current?.id
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(list),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || picked.id == widget.task.taskListId) return;

    // Move via the *current* list's notifier so it picks up the deletion
    // tombstone, then create the same task under the new list.
    final moved = widget.task.copyWith(taskListId: picked.id);
    await ref
        .read(tasksNotifierProvider(widget.task.taskListId).notifier)
        .updateTask(moved);
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
    final scheme = Theme.of(context).colorScheme;
    final tags = widget.task.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TAGS', style: _captionStyle(scheme)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...tags.map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        final updatedTags = tags
                            .where((t) => t != tag)
                            .toList();
                        _updateTask(widget.task.copyWith(tags: updatedTags));
                      },
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _showAddTagDialog,
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Add tag',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurfaceVariant,
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
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Add tag',
            style: GoogleFonts.inter(color: scheme.onSurface),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Tag name',
              hintStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: scheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Add', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final updatedTags = [...widget.task.tags, result];
      _updateTask(widget.task.copyWith(tags: updatedTags));
    }
  }

  Widget _buildNotesSection() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOTES', style: _captionStyle(scheme)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: TextField(
            controller: _notesController,
            onChanged: _onNotesChanged,
            maxLines: null,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 22 / 15,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Notes',
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                height: 22 / 15,
                color: scheme.outline,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'Updated ${_formatDate(widget.task.updated)}',
      style: GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  TextStyle _captionStyle(ColorScheme scheme) => GoogleFonts.inter(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.66,
    color: scheme.onSurfaceVariant,
  );

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

/// Step row inside the inspector. 32 px tall, 18 px circular checkbox.
class _StepItem extends StatelessWidget {
  final TaskStep step;
  final VoidCallback onToggle;

  const _StepItem({required this.step, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      child: SizedBox(
        height: 32,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isCompleted ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: step.isCompleted ? scheme.primary : scheme.outline,
                    width: 1.5,
                  ),
                ),
                child: step.isCompleted
                    ? Icon(Icons.check, size: 10, color: scheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w400,
                    color: step.isCompleted ? scheme.outline : scheme.onSurface,
                    decoration: step.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: scheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 32×32 quiet icon button used in the inspector header.
class _QuietIconButton extends StatelessWidget {
  const _QuietIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppTheme.controlHeight,
      height: AppTheme.controlHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(
              icon,
              size: 18,
              color: color ?? scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inspector metadata row. 96 px label gutter, no decorative chrome,
/// 1 px hairline divider below.
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value ?? '—',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: value == null ? FontWeight.w400 : FontWeight.w500,
                  color: value == null
                      ? scheme.outline
                      : (valueColor ?? scheme.onSurface),
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
