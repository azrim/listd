import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../services/notifications/reminder_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/spring.dart';
import '../utils/url_detector.dart';
import 'context_menu.dart';
import 'inline_edit_field.dart';
import 'link_chip.dart';
import 'list_picker_sheet.dart';
import 'repeat_picker_sheet.dart';
import 'tags_editor_sheet.dart';
import 'task_action_rail.dart';
import 'task_steps_editor.dart';

/// Listd 2027 TaskCard.
///
/// A single rounded island representing one task. Two visual states:
///
///  * **Collapsed** — 56 px tall. Checkbox · title · meta chips · star.
///  * **Expanded**  — 200–400 px. Adds inline editable title, notes,
///    due / star / complete actions. One card may be expanded at a
///    time across the whole list.
///
/// The card owns its own `AnimationController` driven by the standard
/// 2027 spring (`ListdSpring.standard`). When the platform reports
/// `disableAnimations` (reduced motion), the card snaps between states
/// in zero milliseconds.
///
/// Inline edits are debounced — 300 ms for title, 600 ms for notes —
/// and **flushed hard** on three triggers:
///
///  1. Collapse (when `isExpanded` flips `true → false`).
///  2. Dispose (when the card is removed from the tree).
///  3. Task-id swap (when the same widget instance is reused for a
///     different task; should never happen because we key by id).
class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.listId,
    required this.isExpanded,
    required this.onToggleExpand,
    this.isSelected = false,
    this.onTap,
  });

  /// The task to render. Updates from the parent stream are accepted
  /// while the card is collapsed; once expanded, edits in the local
  /// controllers win until they're flushed.
  final Task task;

  /// Real owning list id (for routing mutations through the right
  /// `tasksNotifierProvider`). May differ from the screen the user is
  /// viewing (e.g. virtual `@important`).
  final String listId;

  /// Whether this card is the one expanded card in the list right now.
  /// Driven by `expandedTaskIdProvider` in the screen.
  final bool isExpanded;

  /// Whether this card has the keyboard / programmatic selection.
  /// Selection is independent of expansion — a card can be selected
  /// (highlighted) without being expanded.
  final bool isSelected;

  /// Tap callback for the collapsed card body. The screen typically
  /// uses this to flip `expandedTaskIdProvider` to this task's id.
  final VoidCallback onToggleExpand;

  /// Optional secondary tap (e.g. to also set selection). Most callers
  /// can leave this null and just react to `onToggleExpand`.
  final VoidCallback? onTap;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  static const double _collapsedHeight = 56;
  static const Duration _titleDebounce = Duration(milliseconds: 300);
  static const Duration _notesDebounce = Duration(milliseconds: 600);

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  Timer? _titleTimer;
  Timer? _notesTimer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes);
  }

  @override
  void didUpdateWidget(covariant TaskCard old) {
    super.didUpdateWidget(old);

    // Sync controller text when the upstream Task changes _and_ the
    // user isn't actively editing — same guard as the legacy detail
    // panel so we don't clobber an in-flight typing session.
    if (old.task.title != widget.task.title &&
        _titleController.text == old.task.title) {
      _titleController.text = widget.task.title;
    }
    if (old.task.notes != widget.task.notes &&
        _notesController.text == old.task.notes) {
      _notesController.text = widget.task.notes;
    }

    if (widget.isExpanded != old.isExpanded && !widget.isExpanded) {
      // Hard flush on collapse — never persist mid-debounce edits.
      _flushTitle();
      _flushNotes();
    }
  }

  @override
  void dispose() {
    _flushTitle();
    _flushNotes();
    _titleTimer?.cancel();
    _notesTimer?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTitleChanged(String _) {
    _titleTimer?.cancel();
    _titleTimer = Timer(_titleDebounce, _flushTitle);
  }

  void _onNotesChanged(String _) {
    _notesTimer?.cancel();
    _notesTimer = Timer(_notesDebounce, _flushNotes);
  }

  void _flushTitle() {
    _titleTimer?.cancel();
    final text = _titleController.text;
    if (text == widget.task.title) return;
    _update(widget.task.copyWith(title: text));
  }

  void _flushNotes() {
    _notesTimer?.cancel();
    final text = _notesController.text;
    if (text == widget.task.notes) return;
    _update(widget.task.copyWith(notes: text));
  }

  void _update(Task task) {
    ref.read(tasksNotifierProvider(widget.listId).notifier).updateTask(task);
  }

  void _toggleComplete() {
    ref
        .read(tasksNotifierProvider(widget.listId).notifier)
        .toggleComplete(widget.task);
  }

  void _toggleStar() {
    _update(widget.task.copyWith(isStarred: !widget.task.isStarred));
  }

  void _updateSteps(List<TaskStep> steps) {
    _update(widget.task.copyWith(steps: steps));
  }

  Future<void> _pickDue() async {
    final task = widget.task;
    final initial = task.due ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (!mounted) return;
    if (picked == null) return;
    _update(task.copyWith(due: picked));
  }

  Future<void> _pickReminder() async {
    final task = widget.task;
    final initial =
        task.reminder ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final updated = task.copyWith(reminder: reminder);
    _update(updated);
    // Best-effort schedule; ReminderService no-ops on platforms that
    // don't support local notifications and on past times.
    unawaited(ref.read(reminderServiceProvider).schedule(updated));
  }

  Future<void> _pickRepeat() async {
    final result = await showRepeatPicker(context, initial: widget.task.repeat);
    if (!mounted || result == null) return;
    if (result.value == null) {
      _update(widget.task.copyWith(clearRepeat: true));
    } else {
      _update(widget.task.copyWith(repeat: result.value));
    }
  }

  Future<void> _editTags() async {
    final next = await showTagsEditor(context, initial: widget.task.tags);
    if (!mounted || next == null) return;
    _update(widget.task.copyWith(tags: next));
  }

  Future<void> _confirmDelete() async {
    final taskId = widget.task.id;
    final title = widget.task.title.isEmpty ? 'task' : '"${widget.task.title}"';
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(tasksNotifierProvider(widget.listId).notifier)
        .deleteTask(taskId);
    unawaited(ref.read(reminderServiceProvider).cancel(taskId));
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text('Deleted $title')));
  }

  Future<void> _moveToList() async {
    final picked = await showListPicker(
      context,
      excludeListId: widget.task.taskListId,
    );
    if (!mounted || picked == null) return;
    final notifier = ref.read(tasksNotifierProvider(widget.listId).notifier);
    await notifier.updateTask(widget.task.copyWith(taskListId: picked.id));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Moved to ${picked.title}')));
  }

  Future<void> _copyTitle() async {
    final urls = _stepUrls();
    final base = widget.task.title.isEmpty
        ? '(untitled task)'
        : widget.task.title;
    final payload = urls.isNotEmpty ? '$base\n${urls.first}' : base;
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied task to clipboard')));
  }

  /// Open the right-click menu at [globalPosition]. Built from the
  /// task's current state so the labels reflect what the action will
  /// actually do (e.g. "Reopen" vs "Complete").
  void _showContextMenu(Offset globalPosition) {
    final task = widget.task;
    showListdContextMenu(context, globalPosition, [
      ListdContextMenuItem(
        icon: task.isCompleted
            ? PhosphorIcons.arrowCounterClockwise()
            : PhosphorIcons.check(),
        label: task.isCompleted ? 'Reopen' : 'Complete',
        onTap: _toggleComplete,
      ),
      ListdContextMenuItem(
        icon: PhosphorIcons.star(
          task.isStarred ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
        ),
        label: task.isStarred ? 'Unstar' : 'Star',
        onTap: _toggleStar,
      ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: PhosphorIcons.calendar(),
        label: task.due == null ? 'Set due date' : 'Change due date',
        onTap: _pickDue,
      ),
      ListdContextMenuItem(
        icon: PhosphorIcons.bell(),
        label: task.reminder == null ? 'Set reminder' : 'Change reminder',
        onTap: _pickReminder,
      ),
      ListdContextMenuItem(
        icon: PhosphorIcons.repeat(),
        label: task.repeat == null ? 'Set repeat' : 'Change repeat',
        onTap: _pickRepeat,
      ),
      ListdContextMenuItem(
        icon: PhosphorIcons.tag(),
        label: 'Edit tags',
        onTap: _editTags,
      ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: PhosphorIcons.arrowsLeftRight(),
        label: 'Move to list…',
        onTap: _moveToList,
      ),
      ListdContextMenuItem(
        icon: PhosphorIcons.copy(),
        label: 'Copy task',
        onTap: _copyTitle,
      ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: PhosphorIcons.trash(),
        label: 'Delete',
        onTap: _confirmDelete,
        destructive: true,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();

    final isExpanded = widget.isExpanded;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduced ? Duration.zero : ListdSpring.duration;
    const curve = Curves.easeOutCubic;

    // Collapsed-state fill: indigo-soft on selection, slate-600 wash
    // on hover (one slate stop above the canvas, so the tint is
    // actually visible), otherwise alpha-0 of canvas. The canvas-RGB
    // rest carries the same RGB as the expanded state below so the
    // collapse↔expand morph is a no-op on color when neither hovered
    // nor selected — keeping the card at canvas brightness through
    // the entire morph instead of popping up to slate-700 in dark
    // mode. Same RGB at both endpoints also avoids the
    // lerp-through-black artefact (Color.lerp from RGB-(0,0,0) of
    // Colors.transparent toward chip mid-frames composite to a dark
    // grey on the surface for ~80 ms).
    final Color cardRest = scheme.surface.withValues(alpha: 0);
    final Color collapsedFill;
    if (widget.isSelected) {
      collapsedFill = scheme.primaryContainer;
    } else if (_hovered) {
      collapsedFill = surfaces?.chip ?? scheme.surfaceContainerHigh;
    } else {
      collapsedFill = cardRest;
    }

    // ── Uniform Border.all in both states.
    //
    // The previous attempt had a 4-sided non-uniform Border for the
    // collapsed state (transparent top/right, indigo left bar,
    // hairline bottom). When AnimatedContainer.lerp ran between that
    // and the expanded uniform indigo border, the intermediate
    // frames had non-uniform colors AND a borderRadius — which
    // throws `A borderRadius can only be given on borders with
    // uniform colors` and freezes the whole list.
    //
    // Both states are now Border.all so Border.lerp produces
    // uniform borders frame-by-frame; the bottom hairline + the
    // selected indigo left bar are pulled out as separate sibling
    // widgets so they don't break the uniformity invariant.
    final BoxDecoration decoration = BoxDecoration(
      // Expanded uses the same alpha-0 canvas RGB as the collapsed
      // rest so the card brightness is constant whether collapsed
      // or expanded — the 1.5 px indigo border + shadowMd carry the
      // lift instead. Previously this was `cardBg` (= surfaces.card,
      // slate-700 in dark), which made the expanded card pop one
      // slate stop above the canvas in dark mode and read as
      // "brighter when not hovered".
      color: isExpanded ? cardRest : collapsedFill,
      borderRadius: BorderRadius.circular(isExpanded ? 16 : 0),
      border: Border.all(
        color: isExpanded ? scheme.primary : Colors.transparent,
        width: isExpanded ? 1.5 : 0,
      ),
      boxShadow: isExpanded
          ? [surfaces?.shadowMd ?? const BoxShadow()]
          : const [],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPadding(
            duration: duration,
            curve: curve,
            padding: isExpanded
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : EdgeInsets.zero,
            child: AnimatedContainer(
              duration: duration,
              curve: curve,
              decoration: decoration,
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  // Bound the splash to the rounded shape so the
                  // hover overlay can't bleed past the indigo border
                  // when the card is expanded.
                  borderRadius: BorderRadius.circular(isExpanded ? 16 : 0),
                  // The collapsed card's hover fill is driven
                  // explicitly by `_hovered → collapsedFill = chip`
                  // on the AnimatedContainer above. Letting InkWell
                  // paint its own hover overlay on top would (a)
                  // double-tint the collapsed row and (b) actively
                  // *darken* the expanded card in dark mode, because
                  // the global `theme.hoverColor` resolves to
                  // `scheme.surfaceContainer` (= dark canvas, slate-800)
                  // which lays a darker square on top of the
                  // brighter `card` token. Disabling it here keeps
                  // the expanded card at its resting brightness on
                  // hover and the collapsed row driven by exactly
                  // one hover-fill source.
                  hoverColor: Colors.transparent,
                  onTap: () {
                    widget.onToggleExpand();
                    widget.onTap?.call();
                  },
                  onSecondaryTapDown: (details) =>
                      _showContextMenu(details.globalPosition),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCollapsedRow(scheme, theme),
                          // AnimatedSize uses RenderAnimatedSize, an
                          // actual layout-participating RenderObject,
                          // so ListView.builder always sees the
                          // correct intrinsic height even mid-flight.
                          AnimatedSize(
                            duration: duration,
                            curve: curve,
                            alignment: Alignment.topLeft,
                            child: isExpanded
                                ? _buildExpandedBody(scheme, theme)
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                      // Selected collapsed rows get a 2 px indigo
                      // left bar painted as an overlay — kept out of
                      // the BoxDecoration so the latter stays a
                      // uniform Border.all (see comment above).
                      if (!isExpanded && widget.isSelected)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: scheme.primary),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom hairline between collapsed task rows. Animates
          // away to zero height when the card expands so the
          // expanded card's own border isn't doubled-up underneath.
          AnimatedContainer(
            duration: duration,
            curve: curve,
            height: isExpanded ? 0 : 1,
            color: isExpanded
                ? Colors.transparent
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  /// Pulls every URL out of the task's step list — both steps that are
  /// just a URL (`isUrlOnly`) and steps that mention a URL inline.
  /// De-duplicates so the same link doesn't render twice.
  List<String> _stepUrls() {
    final out = <String>[];
    for (final step in widget.task.steps) {
      for (final u in extractUrls(step.title)) {
        if (!out.contains(u)) out.add(u);
      }
    }
    return out;
  }

  Widget _buildCollapsedRow(ColorScheme scheme, ThemeData theme) {
    final task = widget.task;
    final urls = _stepUrls();
    final firstTag = task.tags.isEmpty ? null : task.tags.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _collapsedHeight,
            child: Row(
              children: [
                _CardCheckbox(
                  completed: task.isCompleted,
                  onTap: _toggleComplete,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    task.title.isEmpty ? 'Untitled task' : task.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 22 / 15,
                      fontWeight: FontWeight.w500,
                      // Completed titles dim down to onSurface @ 0.7
                      // (effective slate-200 dark / slate-700 light),
                      // which keeps them clearly legible while still
                      // reading as muted. `onSurfaceVariant` was too
                      // close to the hairline weight on the slate-700
                      // card; `outline` was completely illegible.
                      color: task.isCompleted
                          ? scheme.onSurface.withValues(alpha: 0.7)
                          : scheme.onSurface,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: scheme.onSurface.withValues(alpha: 0.7),
                      decorationThickness: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (firstTag != null) ...[
                  const SizedBox(width: 8),
                  _TagChip(label: firstTag),
                ],
                if (task.due != null) ...[
                  const SizedBox(width: 8),
                  _DueChip(due: task.due!),
                ],
                if (task.steps.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _MetaChip(
                    label:
                        '${task.steps.where((s) => s.isCompleted).length}/${task.steps.length}',
                    scheme: scheme,
                    icon: PhosphorIcons.checkSquare(),
                  ),
                ],
                if (task.isStarred) ...[
                  const SizedBox(width: 10),
                  Icon(
                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                    size: 16,
                    color: theme.brightness == Brightness.dark
                        ? AppColors.amber300
                        : AppColors.amber400,
                  ),
                ],
              ],
            ),
          ),
          if (urls.isNotEmpty) _buildLinkRail(urls),
        ],
      ),
    );
  }

  /// Up to three [LinkChip]s rendered under the title row when the
  /// task has URL steps. Anything past the third is folded into a
  /// "+N more" overflow chip that just toggles expansion.
  Widget _buildLinkRail(List<String> urls) {
    const visible = 3;
    final shown = urls.take(visible).toList();
    final overflow = urls.length - shown.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 0, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final url in shown) LinkChip(url: url),
          if (overflow > 0)
            LinkOverflowChip(count: overflow, onTap: widget.onToggleExpand),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(ColorScheme scheme, ThemeData theme) {
    final task = widget.task;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 520),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InlineEditField(
                          controller: _titleController,
                          onChanged: _onTitleChanged,
                          placeholder: 'Task title',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.18,
                            color: task.isCompleted
                                ? scheme.outline
                                : scheme.onSurface,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InlineEditField(
                          controller: _notesController,
                          onChanged: _onNotesChanged,
                          maxLines: 3,
                          minLines: 1,
                          placeholder: 'Notes',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'STEPS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 16 / 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.06,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TaskStepsEditor(
                          steps: task.steps,
                          onStepsChanged: _updateSteps,
                          maxHeight: 220,
                        ),
                        if (task.steps.length >= 2) ...[
                          const SizedBox(height: 12),
                          _StepsProgressBar(steps: task.steps),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ActionPill(
                              icon: task.isCompleted
                                  ? PhosphorIcons.arrowCounterClockwise()
                                  : PhosphorIcons.check(),
                              label: task.isCompleted ? 'Reopen' : 'Complete',
                              onTap: _toggleComplete,
                              variant: task.isCompleted
                                  ? _ActionPillVariant.quiet
                                  : _ActionPillVariant.primary,
                            ),
                            const Spacer(),
                            _CreatedFooter(updated: task.updated),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: TaskActionRail(
                      task: task,
                      onToggleStar: _toggleStar,
                      onPickDue: _pickDue,
                      onPickReminder: _pickReminder,
                      onPickRepeat: _pickRepeat,
                      onEditTags: _editTags,
                      onDelete: _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 20 px circular checkbox tuned for the 56 px card row. Slightly
/// larger than the 18 px legacy checkbox so the touch target inside
/// the card body feels comfortable on Linux desktop with a mouse.
class _CardCheckbox extends StatelessWidget {
  const _CardCheckbox({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ListdSpring.duration,
        curve: ListdSpring.curve,
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: completed ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: completed
            ? Icon(Icons.check, size: 12, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}

/// `#tag` chip — indigo-soft fill, indigo-600 fg. Sits in the
/// collapsed row's right meta cluster.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$label',
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w500,
          color: scheme.primary,
        ),
      ),
    );
  }
}

/// `due Mon 11` chip — indigo-soft fill, indigo-600 fg.
class _DueChip extends StatelessWidget {
  const _DueChip({required this.due});

  final DateTime due;

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == -1) return 'yesterday';
    if (diff > 1 && diff < 7) {
      const dows = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return dows[d.weekday - 1];
    }
    const months = [
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
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.calendar(), size: 11, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet meta chip rendered to the right of the title in the collapsed
/// row. Renders as text-only with optional leading icon, no fill — the
/// card itself is the island.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.scheme, this.icon});

  final String label;
  final ColorScheme scheme;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// 28 px action pill in the expanded body. Tinted when the action is
/// in its "on" state (e.g. starred, complete).
enum _ActionPillVariant { primary, quiet }

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.variant = _ActionPillVariant.quiet,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _ActionPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 2027 indigo · Complete pill is the `accent` indigo-600 fill
    // with white text. Reopen / quiet calls render against the
    // surface chip.
    final isPrimary = variant == _ActionPillVariant.primary;
    final fg = isPrimary ? scheme.onPrimary : scheme.onSurfaceVariant;
    final bg = isPrimary ? scheme.primary : scheme.surfaceContainerHighest;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny footer at the bottom of the expanded body — quiet text that
/// records when the task was last touched. Uses tabular figures so
/// timestamps line up across cards in side-by-side comparisons.
class _CreatedFooter extends StatelessWidget {
  const _CreatedFooter({required this.updated});

  final DateTime updated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final localUpdated = updated.toLocal();
    final delta = now.difference(localUpdated);
    final label = delta.inDays > 7
        ? '${localUpdated.month}/${localUpdated.day}/${localUpdated.year}'
        : delta.inDays >= 1
        ? '${delta.inDays}d ago'
        : delta.inHours >= 1
        ? '${delta.inHours}h ago'
        : delta.inMinutes >= 1
        ? '${delta.inMinutes}m ago'
        : 'Just now';
    return Text(
      'Edited $label · saves automatically',
      style: GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 4 px hairline progress bar shown above the Complete pill when a
/// task has 2+ steps. Track is `outlineVariant`; fill is the indigo
/// accent.
class _StepsProgressBar extends StatelessWidget {
  const _StepsProgressBar({required this.steps});

  final List<TaskStep> steps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = steps.length;
    final done = steps.where((s) => s.isCompleted).length;
    final value = total == 0 ? 0.0 : done / total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: scheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                minHeight: 4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$done/$total done',
          style: GoogleFonts.inter(
            fontSize: 11,
            height: 16 / 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
