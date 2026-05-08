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
  /// Debounce for typed-in fields. Click-driven mutations (checkbox, star,
  /// pickers) intentionally write through immediately — only keystrokes pay
  /// the cost of waiting.
  static const Duration _titleDebounce = Duration(milliseconds: 300);
  static const Duration _notesDebounce = Duration(milliseconds: 600);

  late TextEditingController _titleController;
  late TextEditingController _notesController;
  Timer? _titleTimer;
  Timer? _notesTimer;

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
      // User selected a different task — flush any pending edits on the old
      // one before swapping controller contents.
      _flushTitle(oldWidget.task);
      _flushNotes(oldWidget.task);
      _titleController.text = widget.task.title;
      _notesController.text = widget.task.notes;
      return;
    }
    // Same task, fresh data from the stream. Only sync the controller when the
    // user isn't actively editing (text differs from both old AND new), to
    // avoid clobbering an in-flight typing session.
    if (oldWidget.task.title != widget.task.title &&
        _titleController.text == oldWidget.task.title) {
      _titleController.text = widget.task.title;
    }
    if (oldWidget.task.notes != widget.task.notes &&
        _notesController.text == oldWidget.task.notes) {
      _notesController.text = widget.task.notes;
    }
  }

  @override
  void dispose() {
    _flushTitle(widget.task);
    _flushNotes(widget.task);
    _titleTimer?.cancel();
    _notesTimer?.cancel();
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
    _titleTimer?.cancel();
    _titleTimer = Timer(_titleDebounce, () => _flushTitle(widget.task));
  }

  void _onNotesChanged(String value) {
    _notesTimer?.cancel();
    _notesTimer = Timer(_notesDebounce, () => _flushNotes(widget.task));
  }

  void _flushTitle(Task target) {
    _titleTimer?.cancel();
    final text = _titleController.text;
    if (text == target.title) return;
    _updateTask(target.copyWith(title: text));
  }

  void _flushNotes(Task target) {
    _notesTimer?.cancel();
    final text = _notesController.text;
    if (text == target.notes) return;
    _updateTask(target.copyWith(notes: text));
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
        _SectionHeader(
          label: 'STEPS',
          trailing: steps.isEmpty ? null : '$completedCount of ${steps.length}',
        ),
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
        _AddRow(
          label: 'Add step',
          onTap: _showAddStepDialog,
          color: scheme.onSurfaceVariant,
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
    final lists =
        ref.watch(taskListsNotifierProvider).valueOrNull ?? const <TaskList>[];
    final owningList = lists
        .where((l) => l.id == widget.task.taskListId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: 'DETAILS'),
        _MetadataRow(
          icon: Icons.folder_outlined,
          label: 'Folder',
          value: owningList?.title ?? 'Tasks',
          onTap: () => _showFolderPicker(lists, owningList),
        ),
        _MetadataRow(
          icon: Icons.notifications_outlined,
          label: 'Remind me',
          value: widget.task.hasReminder
              ? _formatTime(widget.task.reminder!)
              : null,
          placeholder: 'Set a reminder',
          onTap: () => _showReminderPicker(),
        ),
        _MetadataRow(
          icon: Icons.calendar_today_outlined,
          label: 'Due date',
          value: widget.task.hasDueDate ? _formatDate(widget.task.due!) : null,
          placeholder: 'Pick a date',
          onTap: () => _showDueDatePicker(),
        ),
        _MetadataRow(
          icon: Icons.repeat,
          label: 'Repeat',
          value: widget.task.hasRepeat ? widget.task.repeat!.type.name : null,
          placeholder: 'No repeat',
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
        const _SectionHeader(label: 'TAGS'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in tags)
                _InlineTag(
                  label: tag,
                  onRemove: () {
                    final updatedTags = tags.where((t) => t != tag).toList();
                    _updateTask(widget.task.copyWith(tags: updatedTags));
                  },
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showAddTagDialog,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: scheme.onSurfaceVariant),
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
            ],
          ),
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
        const _SectionHeader(label: 'NOTES'),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
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
              hintText: 'Add notes…',
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                height: 22 / 15,
                color: scheme.outline,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
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

/// Caption header used above every section ("DETAILS", "STEPS", "TAGS",
/// "NOTES"). 11 px, 600w, all-caps, with optional trailing meta (e.g. step
/// progress count). Bottom padding sits the rows on the 4 px grid.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 16 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.66,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
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
    );
  }
}

/// 36 px row used both for steps and metadata. No rounded ink, full-row
/// hover fill of `surface-sunken` so the affordance reads like a sidebar
/// item — same as the rest of the app.
class _InspectorRow extends StatelessWidget {
  const _InspectorRow({required this.child, this.onTap, this.divider = false});

  final Widget child;
  final VoidCallback? onTap;

  /// Hairline at the bottom edge. Used between metadata rows so the section
  /// reads as labeled fields rather than a free-form list.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: scheme.surfaceContainerHighest,
        // No borderRadius — rectangular hover fill that aligns with the
        // bottom hairline.
        child: Container(
          height: 36,
          decoration: divider
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                )
              : null,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

/// Step row inside the inspector. Uses `_InspectorRow` so it reads with
/// the same height + hover affordance as metadata rows. 18 px circular
/// checkbox to match the title row and the left list.
class _StepItem extends StatelessWidget {
  final TaskStep step;
  final VoidCallback onToggle;

  const _StepItem({required this.step, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _InspectorRow(
      onTap: onToggle,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.isCompleted ? scheme.primary : Colors.transparent,
              border: Border.all(
                color: step.isCompleted ? scheme.primary : scheme.outline,
                width: 1.5,
              ),
            ),
            child: step.isCompleted
                ? Icon(Icons.check, size: 12, color: scheme.onPrimary)
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
    );
  }
}

/// "+ Add step" / "+ Add tag" affordance. Same row metrics as the rest
/// of the section so the click target lines up.
class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _InspectorRow(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.add, size: 14, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline text tag — no border, no fill, no chip. Reads as a word with
/// a hairline-color × on hover for removal.
class _InlineTag extends StatefulWidget {
  const _InlineTag({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  State<_InlineTag> createState() => _InlineTagState();
}

class _InlineTagState extends State<_InlineTag> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: _hovered
                ? Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: widget.onRemove,
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
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

/// Inspector metadata row. 36 px tall (matches every other row in the
/// inspector + the sidebar), 14 px icon, 96 px label gutter, hairline at
/// the bottom edge so the section reads as a stack of labeled fields.
/// Empty values render as `Add <label>` in the tertiary text color so the
/// whole row reads as a single coherent unit.
class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? placeholder;
  final VoidCallback? onTap;

  const _MetadataRow({
    required this.icon,
    required this.label,
    this.value,
    this.placeholder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null;
    return _InspectorRow(
      onTap: onTap,
      divider: true,
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
              hasValue ? value! : (placeholder ?? '—'),
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                color: hasValue ? scheme.onSurface : scheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
