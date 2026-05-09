import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import '../theme/spring.dart';

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

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  static const double _collapsedHeight = 56;
  static const Duration _titleDebounce = Duration(milliseconds: 300);
  static const Duration _notesDebounce = Duration(milliseconds: 600);

  late final AnimationController _expand;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  Timer? _titleTimer;
  Timer? _notesTimer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: ListdSpring.duration,
      reverseDuration: ListdSpring.duration,
      value: widget.isExpanded ? 1.0 : 0.0,
    );
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

    if (widget.isExpanded != old.isExpanded) {
      _animateExpand(widget.isExpanded);
      if (!widget.isExpanded) {
        // Hard flush on collapse — never persist mid-debounce edits.
        _flushTitle();
        _flushNotes();
      }
    }
  }

  void _animateExpand(bool expanded) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _expand.value = expanded ? 1.0 : 0.0;
      return;
    }
    final spring = SpringSimulation(
      ListdSpring.standard,
      _expand.value,
      expanded ? 1.0 : 0.0,
      0,
    );
    _expand.animateWith(spring);
  }

  @override
  void dispose() {
    _flushTitle();
    _flushNotes();
    _titleTimer?.cancel();
    _notesTimer?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    _expand.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.card ?? scheme.surface;

    Color fill = cardBg;
    if (widget.isSelected) {
      fill = scheme.primaryContainer;
    } else if (_hovered) {
      fill = Color.alphaBlend(scheme.primary.withValues(alpha: 0.04), cardBg);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _expand,
        builder: (context, _) {
          final t = _expand.value.clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isSelected
                    ? scheme.primary.withValues(alpha: 0.4)
                    : scheme.outlineVariant,
                width: 1,
              ),
              boxShadow: t > 0
                  ? [surfaces?.shadowSm ?? const BoxShadow()]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onToggleExpand();
                  widget.onTap?.call();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCollapsedRow(scheme, theme),
                    if (t > 0)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          heightFactor: t,
                          child: Opacity(
                            opacity: t,
                            child: _buildExpandedBody(scheme, theme),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedRow(ColorScheme scheme, ThemeData theme) {
    final task = widget.task;
    return SizedBox(
      height: _collapsedHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _CardCheckbox(completed: task.isCompleted, onTap: _toggleComplete),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                task.title.isEmpty ? 'Untitled task' : task.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w500,
                  color: task.isCompleted ? scheme.outline : scheme.onSurface,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: scheme.outline,
                  decorationThickness: 1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (task.due != null) ...[
              const SizedBox(width: 12),
              _MetaChip(label: _formatDate(task.due!), scheme: scheme),
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
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                size: 16,
                color: scheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBody(ColorScheme scheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          // Inline editable title — bigger + serif-y feel via Inter 500.
          TextField(
            controller: _titleController,
            onChanged: _onTitleChanged,
            style: GoogleFonts.inter(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.18,
              color: widget.task.isCompleted
                  ? scheme.outline
                  : scheme.onSurface,
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'Task title',
              hintStyle: GoogleFonts.inter(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.18,
                color: scheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Inline editable notes.
          TextField(
            controller: _notesController,
            onChanged: _onNotesChanged,
            maxLines: null,
            minLines: 1,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'Notes',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                height: 20 / 14,
                color: scheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionPill(
                icon: widget.task.isStarred
                    ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                    : PhosphorIcons.star(),
                label: widget.task.isStarred ? 'Starred' : 'Star',
                onTap: _toggleStar,
                tinted: widget.task.isStarred,
              ),
              const SizedBox(width: 8),
              if (widget.task.due != null)
                _ActionPill(
                  icon: PhosphorIcons.calendar(),
                  label: _formatDate(widget.task.due!),
                  onTap: () {},
                ),
              const Spacer(),
              _ActionPill(
                icon: widget.task.isCompleted
                    ? PhosphorIcons.arrowCounterClockwise()
                    : PhosphorIcons.check(),
                label: widget.task.isCompleted ? 'Reopen' : 'Complete',
                onTap: _toggleComplete,
                tinted: !widget.task.isCompleted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    return '${date.month}/${date.day}';
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
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tinted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = tinted ? scheme.primary : scheme.onSurfaceVariant;
    final bg = tinted
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
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
