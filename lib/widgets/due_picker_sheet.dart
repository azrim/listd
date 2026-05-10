import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'hoverable_surface.dart';
import 'sheet_shell.dart';

/// Result returned from the Listd 2027 due-date picker.
///
///   * `null` (the dialog popped without changes) — caller leaves
///     the task's due date untouched.
///   * `DueDateResult(value: null)` — user explicitly chose
///     "Clear due date".
///   * `DueDateResult(value: <DateTime>)` — the chosen date at
///     midnight local.
class DueDateResult {
  const DueDateResult(this.value);
  final DateTime? value;
}

/// Pops the Listd 2027 due-date picker — palette-shell with quick-
/// preset chips, an inline 7-column month grid, and Phosphor month
/// nav. Replaces Flutter's stock `showDatePicker` so the surface
/// reads the same as every other overlay in the app.
Future<DueDateResult?> showDueDatePicker(
  BuildContext context, {
  DateTime? initial,
}) {
  return showSheetShell<DueDateResult>(
    context,
    (ctx) => _DueDatePickerSheet(initial: initial),
  );
}

class _DueDatePickerSheet extends StatefulWidget {
  const _DueDatePickerSheet({this.initial});

  final DateTime? initial;

  @override
  State<_DueDatePickerSheet> createState() => _DueDatePickerSheetState();
}

class _DueDatePickerSheetState extends State<_DueDatePickerSheet> {
  late DateTime _viewMonth;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final base = widget.initial ?? _today();
    _viewMonth = DateTime(base.year, base.month);
    _selected = widget.initial == null
        ? null
        : DateTime(base.year, base.month, base.day);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  void _pick(DateTime day) {
    Navigator.of(context).pop(DueDateResult(day));
  }

  void _clear() {
    Navigator.of(context).pop(const DueDateResult(null));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SheetShell(
      title: 'Due date',
      icon: PhosphorIcons.calendar(),
      headerActions: widget.initial == null
          ? null
          : [SheetShellClearButton(onPressed: _clear, tooltip: 'Clear due')],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick-preset chips. Today / Tomorrow / Next week / Clear.
            // Mirrors the muscle-memory Linear / Things 3 pattern so
            // the common cases never require the calendar grid.
            _QuickRow(
              hasInitial: widget.initial != null,
              onPick: _pick,
              onClear: _clear,
            ),
            const SizedBox(height: 16),
            _MonthHeader(
              month: _viewMonth,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 6),
            _WeekdayHeader(scheme: scheme),
            const SizedBox(height: 4),
            _MonthGrid(
              month: _viewMonth,
              selected: _selected,
              today: _today(),
              onPick: _pick,
              isSameDay: _sameDay,
            ),
          ],
        ),
      ),
      footer: SheetShellActionFooter(
        leading: widget.initial == null
            ? null
            : TextButton(onPressed: _clear, child: const Text('Clear')),
        trailing: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.hasInitial,
    required this.onPick,
    required this.onClear,
  });

  final bool hasInitial;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final today = _DueDatePickerSheetState._today();
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(label: 'Today', onTap: () => onPick(today)),
        _Chip(label: 'Tomorrow', onTap: () => onPick(tomorrow)),
        _Chip(label: 'Next week', onTap: () => onPick(nextWeek)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return HoverableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      fillFor: (_, {required hovered, required selected}) => hovered
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerHighest.withValues(alpha: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_months[month.month - 1]} ${month.year}',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: onPrev,
          icon: Icon(PhosphorIcons.caretLeft(), size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Previous month',
          color: scheme.onSurfaceVariant,
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(PhosphorIcons.caretRight(), size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Next month',
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(
                l,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 16 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.onPick,
    required this.isSameDay,
  });

  final DateTime month;
  final DateTime? selected;
  final DateTime today;
  final ValueChanged<DateTime> onPick;
  final bool Function(DateTime, DateTime) isSameDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first week: weekday 1 (Mon) → leading 0, …, weekday 7
    // (Sun) → leading 6.
    final leading = (firstOfMonth.weekday - 1) % 7;
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final isSelected = selected != null && isSameDay(day, selected!);
      final isToday = isSameDay(day, today);
      cells.add(
        _DayCell(
          day: d,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => onPick(day),
          scheme: scheme,
        ),
      );
    }
    // Pad to a complete grid (multiples of 7).
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1.05,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    required this.scheme,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return HoverableSurface(
      onTap: onTap,
      selected: isSelected,
      borderRadius: BorderRadius.circular(8),
      // Today badge is a 1 px indigo hairline; rest fill stays in
      // the chip family at alpha 0 so the cross-fade is alpha-only.
      border: isToday && !isSelected
          ? Border.all(color: scheme.primary, width: 1)
          : null,
      fillFor: (_, {required hovered, required selected}) {
        if (selected) return scheme.primaryContainer;
        if (hovered) return scheme.surfaceContainerHighest;
        return scheme.surfaceContainerHighest.withValues(alpha: 0);
      },
      child: Center(
        child: Text(
          '$day',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
