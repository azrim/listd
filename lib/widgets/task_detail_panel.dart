import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_text_field.dart';

/// Task detail panel showing full task information with all features.
class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.onUpdate,
    this.onDelete,
  });

  final Task task;
  final Function(Task) onUpdate;
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

  void _onTitleChanged(String value) {
    widget.onUpdate(widget.task.copyWith(title: value));
  }

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 800), () {
      widget.onUpdate(widget.task.copyWith(notes: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                    _StepsSection(
                      steps: widget.task.steps,
                      onStepsChanged: (steps) {
                        widget.onUpdate(widget.task.copyWith(steps: steps));
                      },
                    ),
                    const SizedBox(height: 24),
                    _MetadataRows(
                      task: widget.task,
                      onReminderChanged: (reminder) {
                        widget.onUpdate(
                          widget.task.copyWith(
                            reminder: reminder,
                            clearReminder: reminder == null,
                          ),
                        );
                      },
                      onDueChanged: (due) {
                        widget.onUpdate(
                          widget.task.copyWith(due: due, clearDue: due == null),
                        );
                      },
                      onRepeatChanged: (repeat) {
                        widget.onUpdate(
                          widget.task.copyWith(
                            repeat: repeat,
                            clearRepeat: repeat == null,
                          ),
                        );
                      },
                      onTagsChanged: (tags) {
                        widget.onUpdate(widget.task.copyWith(tags: tags));
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildFooter(context),
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
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withAlpha(128),
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder.withAlpha(64)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.textSecondary,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: widget.onDelete,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        _TaskCheckbox(
          isCompleted: widget.task.isCompleted,
          onChanged: (value) {
            final newStatus = value ? 'completed' : 'needsAction';
            widget.onUpdate(widget.task.copyWith(status: newStatus));
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _titleController,
            onChanged: _onTitleChanged,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Task title',
              hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textHint),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            widget.task.isStarred ? Icons.star : Icons.star_border,
            color: widget.task.isStarred
                ? Colors.amber
                : AppColors.textSecondary,
          ),
          onPressed: () {
            widget.onUpdate(
              widget.task.copyWith(isStarred: !widget.task.isStarred),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GlassTextField(
          controller: _notesController,
          onChanged: _onNotesChanged,
          hint: 'Add a note...',
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Created ${_formatDate(widget.task.updated)}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
        TextButton.icon(
          onPressed: widget.onDelete,
          icon: const Icon(
            Icons.delete_outline,
            size: 16,
            color: AppColors.danger,
          ),
          label: Text(
            'Delete',
            style: GoogleFonts.spaceGrotesk(color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Circular checkbox.
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.isCompleted, required this.onChanged});

  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isCompleted ? AppColors.primary : AppColors.textHint,
            width: 2,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(140),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Steps section with reorderable list.
class _StepsSection extends StatefulWidget {
  const _StepsSection({required this.steps, required this.onStepsChanged});

  final List<TaskStep> steps;
  final Function(List<TaskStep>) onStepsChanged;

  @override
  State<_StepsSection> createState() => _StepsSectionState();
}

class _StepsSectionState extends State<_StepsSection> {
  final _addController = TextEditingController();

  void _addStep() {
    final title = _addController.text.trim();
    if (title.isEmpty) return;
    final newStep = TaskStep(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    widget.onStepsChanged([...widget.steps, newStep]);
    _addController.clear();
  }

  void _deleteStep(String stepId) {
    widget.onStepsChanged(widget.steps.where((s) => s.id != stepId).toList());
  }

  void _toggleStep(String stepId) {
    widget.onStepsChanged(
      widget.steps.map((s) {
        if (s.id == stepId) return s.copyWith(isCompleted: !s.isCompleted);
        return s;
      }).toList(),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.steps.isNotEmpty) ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.steps.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final steps = List<TaskStep>.from(widget.steps);
              final step = steps.removeAt(oldIndex);
              steps.insert(newIndex, step);
              widget.onStepsChanged(steps);
            },
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              return _StepTile(
                key: Key(step.id),
                step: step,
                onToggle: () => _toggleStep(step.id),
                onDelete: () => _deleteStep(step.id),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            const Icon(Icons.add, size: 20, color: AppColors.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _addController,
                onSubmitted: (_) => _addStep(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a step...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 20, color: AppColors.primary),
              onPressed: _addStep,
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual step tile.
class _StepTile extends StatelessWidget {
  const _StepTile({
    super.key,
    required this.step,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskStep step;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  Future<void> _launchUrl() async {
    final uri = Uri.parse(step.title);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismiss_${step.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder.withAlpha(64)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isCompleted
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: step.isCompleted
                        ? AppColors.primary
                        : AppColors.textHint,
                    width: 2,
                  ),
                ),
                child: step.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: step.isLink
                  ? InkWell(
                      onTap: _launchUrl,
                      child: Text(
                        step.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: AppColors.primary,
                          decoration: step.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      step.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: step.isCompleted
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        decoration: step.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
            ),
            const Icon(Icons.drag_handle, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// Metadata rows.
class _MetadataRows extends StatelessWidget {
  const _MetadataRows({
    required this.task,
    required this.onReminderChanged,
    required this.onDueChanged,
    required this.onRepeatChanged,
    required this.onTagsChanged,
  });

  final Task task;
  final ValueChanged<DateTime?> onReminderChanged;
  final ValueChanged<DateTime?> onDueChanged;
  final ValueChanged<RepeatConfig?> onRepeatChanged;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetadataRow(
          icon: Icons.notifications_outlined,
          activeIcon: task.hasReminder,
          label: 'Remind me',
          value: task.hasReminder ? _formatReminder(task.reminder!) : null,
          valueColor: AppColors.primary,
          onTap: () => _showReminderPicker(context),
          onClear: task.hasReminder ? () => onReminderChanged(null) : null,
        ),
        _MetadataRow(
          icon: Icons.calendar_today_outlined,
          activeIcon: task.hasDueDate,
          label: 'Due date',
          value: task.hasDueDate ? _formatDueDate(task.due!) : null,
          valueColor: _getDueDateColor(task.due!),
          onTap: () => _showDatePicker(context),
          onClear: task.hasDueDate ? () => onDueChanged(null) : null,
        ),
        _MetadataRow(
          icon: Icons.repeat,
          activeIcon: task.hasRepeat,
          label: 'Repeat',
          value: task.hasRepeat ? _formatRepeat(task.repeat!) : null,
          onTap: () => _showRepeatPicker(context),
          onClear: task.hasRepeat ? () => onRepeatChanged(null) : null,
        ),
        _MetadataRow(
          icon: Icons.label_outline,
          activeIcon: task.tags.isNotEmpty,
          label: 'Tags',
          value: task.tags.isNotEmpty ? task.tags.join(', ') : null,
          onTap: () => _showTagsPicker(context),
          onClear: task.tags.isNotEmpty ? () => onTagsChanged([]) : null,
        ),
      ],
    );
  }

  Future<void> _showReminderPicker(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = task.reminder ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => _DatePickerTheme(child!),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => _TimePickerTheme(child!),
    );
    if (time == null) return;

    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onReminderChanged(reminder);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: task.due ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) => _DatePickerTheme(child!),
    );
    if (date != null) onDueChanged(date);
  }

  void _showRepeatPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RepeatBottomSheet(
        currentRepeat: task.repeat,
        onSelected: (repeat) {
          onRepeatChanged(repeat);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTagsPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagsBottomSheet(
        currentTags: task.tags,
        onTagsChanged: onTagsChanged,
      ),
    );
  }

  String _formatReminder(DateTime reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(reminder.year, reminder.month, reminder.day);

    String dateStr;
    if (reminderDay == today) {
      dateStr = 'Today';
    } else if (reminderDay == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${reminder.month}/${reminder.day}';
    }

    final hour = reminder.hour;
    final minute = reminder.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $period';

    return '$dateStr $timeStr';
  }

  String _formatDueDate(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${-diff} days ago';
    return '${due.month}/${due.day}';
  }

  Color _getDueDateColor(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;

    if (diff < 0) return AppColors.danger;
    if (diff == 0) return AppColors.primary;
    return AppColors.textSecondary;
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

/// Metadata row.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.activeIcon = false,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final bool activeIcon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: activeIcon
                    ? AppColors.primary
                    : (value != null ? valueColor : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (value != null) ...[
                Text(
                  value!,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textSecondary,
                  ),
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ] else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date picker theme.
class _DatePickerTheme extends StatelessWidget {
  const _DatePickerTheme(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.bgSurface,
        ),
      ),
      child: child,
    );
  }
}

/// Time picker theme.
class _TimePickerTheme extends StatelessWidget {
  const _TimePickerTheme(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.bgSurface,
        ),
      ),
      child: child,
    );
  }
}

/// Repeat bottom sheet.
class _RepeatBottomSheet extends StatefulWidget {
  const _RepeatBottomSheet({
    required this.currentRepeat,
    required this.onSelected,
  });

  final RepeatConfig? currentRepeat;
  final ValueChanged<RepeatConfig?> onSelected;

  @override
  State<_RepeatBottomSheet> createState() => _RepeatBottomSheetState();
}

class _RepeatBottomSheetState extends State<_RepeatBottomSheet> {
  late RepeatType _selectedType;
  int _interval = 1;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentRepeat?.type ?? RepeatType.daily;
    _interval = widget.currentRepeat?.interval ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Repeat',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RepeatType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    type.name[0].toUpperCase() + type.name.substring(1),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => widget.onSelected(null),
            child: Text(
              'Clear',
              style: GoogleFonts.spaceGrotesk(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              widget.onSelected(
                RepeatConfig(type: _selectedType, interval: _interval),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tags bottom sheet.
class _TagsBottomSheet extends StatefulWidget {
  const _TagsBottomSheet({
    required this.currentTags,
    required this.onTagsChanged,
  });

  final List<String> currentTags;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  State<_TagsBottomSheet> createState() => _TagsBottomSheetState();
}

class _TagsBottomSheetState extends State<_TagsBottomSheet> {
  late List<String> _selectedTags;
  final _newTagController = TextEditingController();
  final _suggestedTags = [
    'work',
    'personal',
    'shopping',
    'health',
    'finance',
    'travel',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.currentTags);
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _addNewTag() {
    final tag = _newTagController.text.trim();
    if (tag.isEmpty || _selectedTags.contains(tag)) return;
    setState(() => _selectedTags.add(tag));
    _newTagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tags',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => _toggleTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTagController,
                  onSubmitted: (_) => _addNewTag(),
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'New tag...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      color: AppColors.textHint,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addNewTag,
                icon: const Icon(Icons.add, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onTagsChanged(_selectedTags);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
