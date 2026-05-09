import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import 'hoverable_surface.dart';

/// Right-column "metadata rail" inside the expanded `TaskCard`. Shows
/// one row per editable metadata facet — star, due, reminder, repeat,
/// tags, delete — with the current value (or "Add …" placeholder)
/// rendered to the right.
///
/// All callbacks are required so the parent decides what UI to summon
/// (date picker, time picker, modal sheet, tag editor) — keeping the
/// rail itself purely presentational.
class TaskActionRail extends StatelessWidget {
  const TaskActionRail({
    super.key,
    required this.task,
    required this.onToggleStar,
    required this.onPickDue,
    required this.onPickReminder,
    required this.onPickRepeat,
    required this.onEditTags,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggleStar;
  final VoidCallback onPickDue;
  final VoidCallback onPickReminder;
  final VoidCallback onPickRepeat;
  final VoidCallback onEditTags;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionRow(
          icon: task.isStarred
              ? PhosphorIcons.star(PhosphorIconsStyle.fill)
              : PhosphorIcons.star(),
          label: task.isStarred ? 'Starred' : 'Star',
          tinted: task.isStarred,
          iconOverride: task.isStarred
              ? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.amber300
                    : AppColors.amber400)
              : null,
          onTap: onToggleStar,
        ),
        _ActionRow(
          icon: PhosphorIcons.calendar(),
          label: 'Due',
          value: task.due == null ? 'Add date' : _formatDate(task.due!),
          tinted: task.due != null,
          onTap: onPickDue,
        ),
        _ActionRow(
          icon: PhosphorIcons.bell(),
          label: 'Remind',
          value: task.reminder == null
              ? 'Add reminder'
              : _formatDateTime(task.reminder!),
          tinted: task.reminder != null,
          onTap: onPickReminder,
        ),
        _ActionRow(
          icon: PhosphorIcons.repeat(),
          label: 'Repeat',
          value: task.repeat == null
              ? 'No repeat'
              : _formatRepeat(task.repeat!),
          tinted: task.repeat != null,
          onTap: onPickRepeat,
        ),
        _ActionRow(
          icon: PhosphorIcons.tag(),
          label: 'Tags',
          value: task.tags.isEmpty ? 'Add tags' : null,
          valueWidget: task.tags.isEmpty ? null : _TagChips(tags: task.tags),
          tinted: task.tags.isNotEmpty,
          onTap: onEditTags,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        _ActionRow(
          icon: PhosphorIcons.trash(),
          label: 'Delete task',
          tinted: false,
          destructive: true,
          onTap: onDelete,
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${d.month}/${d.day}/${d.year % 100}';
  }

  String _formatDateTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${_formatDate(d)} $hh:$mm';
  }

  String _formatRepeat(RepeatConfig r) {
    final unit = switch (r.type) {
      RepeatType.daily => 'day',
      RepeatType.weekly => 'week',
      RepeatType.monthly => 'month',
      RepeatType.yearly => 'year',
      RepeatType.custom => 'time',
    };
    if (r.interval == 1) return 'Every $unit';
    return 'Every ${r.interval} ${unit}s';
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.tinted = false,
    this.destructive = false,
    this.iconOverride,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;

  /// Optional rich value widget that renders to the right of [label]
  /// instead of the plain `value` text. Used by the Tags row to show
  /// `#tag` indigo-soft chips per `04_task_expanded_light.png`.
  final Widget? valueWidget;
  final bool tinted;
  final bool destructive;
  final Color? iconOverride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = destructive
        ? scheme.error
        : tinted
        ? scheme.primary
        : scheme.onSurface;
    final secondaryFg = destructive
        ? scheme.error.withValues(alpha: 0.7)
        : scheme.onSurfaceVariant;
    final hoverFill = scheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return HoverableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      fillFor: (_, {required hovered, required selected}) =>
          hovered ? hoverFill : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconOverride ?? fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (valueWidget != null) ...[
              const SizedBox(width: 8),
              Flexible(child: valueWidget!),
            ] else if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w400,
                    color: secondaryFg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `#tag` chips rendered to the right of the Tags label per
/// `docs/redesign/2027-indigo/mockups/04_task_expanded_light.png`. Each
/// chip is an indigo-soft pill with a `#`-prefixed label.
class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        for (final t in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t.startsWith('#') ? t : '#$t',
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w500,
                color: scheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
