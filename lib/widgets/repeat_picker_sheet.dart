import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task.dart';
import 'hoverable_surface.dart';
import 'sheet_shell.dart';

/// Result returned from the Listd 2027 repeat picker.
///
///   * `null` — sheet was dismissed without changes.
///   * `RepeatResult(value: null)` — the user explicitly cleared the
///     repeat configuration ("Don't repeat").
///   * `RepeatResult(value: <RepeatConfig>)` — the new schedule.
class RepeatResult {
  const RepeatResult(this.value);
  final RepeatConfig? value;
}

/// Pops the Listd 2027 repeat picker — palette-shell with one row
/// per [RepeatType]. The selected row inline-expands a tail with the
/// interval stepper (and weekday chips for `weekly`) so the picker
/// stays a single column instead of the previous chip rail + stepper
/// stack.
Future<RepeatResult?> showRepeatPicker(
  BuildContext context, {
  RepeatConfig? initial,
}) {
  return showSheetShell<RepeatResult>(
    context,
    (ctx) => _RepeatPickerSheet(initial: initial),
  );
}

class _RepeatPickerSheet extends StatefulWidget {
  const _RepeatPickerSheet({this.initial});
  final RepeatConfig? initial;

  @override
  State<_RepeatPickerSheet> createState() => _RepeatPickerSheetState();
}

class _RepeatPickerSheetState extends State<_RepeatPickerSheet> {
  late RepeatType _type;
  late int _interval;
  late List<int> _weekDays;

  @override
  void initState() {
    super.initState();
    _type = widget.initial?.type ?? RepeatType.daily;
    _interval = widget.initial?.interval ?? 1;
    _weekDays = List.of(widget.initial?.weekDays ?? const <int>[]);
  }

  void _commit() {
    final config = RepeatConfig(
      type: _type,
      interval: _interval,
      weekDays: _type == RepeatType.weekly && _weekDays.isNotEmpty
          ? List.of(_weekDays)
          : null,
    );
    Navigator.of(context).pop(RepeatResult(config));
  }

  void _clear() {
    Navigator.of(context).pop(const RepeatResult(null));
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Repeat',
      icon: PhosphorIcons.repeat(),
      headerActions: widget.initial == null
          ? null
          : [SheetShellClearButton(onPressed: _clear, tooltip: "Don't repeat")],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final t in RepeatType.values)
              _TypeRow(
                type: t,
                isSelected: _type == t,
                interval: _interval,
                weekDays: _weekDays,
                onSelect: () => setState(() => _type = t),
                onIntervalChanged: (v) =>
                    setState(() => _interval = v.clamp(1, 99)),
                onToggleWeekDay: (day) => setState(() {
                  if (_weekDays.contains(day)) {
                    _weekDays.remove(day);
                  } else {
                    _weekDays.add(day);
                  }
                }),
              ),
          ],
        ),
      ),
      footer: SheetShellActionFooter(
        leading: TextButton(
          onPressed: _clear,
          child: const Text("Don't repeat"),
        ),
        trailing: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _commit, child: const Text('Save')),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.isSelected,
    required this.interval,
    required this.weekDays,
    required this.onSelect,
    required this.onIntervalChanged,
    required this.onToggleWeekDay,
  });

  final RepeatType type;
  final bool isSelected;
  final int interval;
  final List<int> weekDays;
  final VoidCallback onSelect;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onToggleWeekDay;

  String get _label => switch (type) {
    RepeatType.daily => 'Daily',
    RepeatType.weekly => 'Weekly',
    RepeatType.monthly => 'Monthly',
    RepeatType.yearly => 'Yearly',
    RepeatType.custom => 'Custom',
  };

  String get _intervalLabel => switch (type) {
    RepeatType.daily => 'Every N days',
    RepeatType.weekly => 'Every N weeks',
    RepeatType.monthly => 'Every N months',
    RepeatType.yearly => 'Every N years',
    RepeatType.custom => 'Every N',
  };

  IconData get _icon => switch (type) {
    RepeatType.daily => PhosphorIcons.calendarBlank(),
    RepeatType.weekly => PhosphorIcons.calendarBlank(),
    RepeatType.monthly => PhosphorIcons.calendar(),
    RepeatType.yearly => PhosphorIcons.calendarStar(),
    RepeatType.custom => PhosphorIcons.dotsThreeOutline(),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HoverableSurface(
            onTap: onSelect,
            selected: isSelected,
            borderRadius: BorderRadius.circular(10),
            fillFor: (_, {required hovered, required selected}) {
              if (selected) return scheme.primaryContainer;
              if (hovered) return scheme.surfaceContainerHighest;
              return scheme.primaryContainer.withValues(alpha: 0);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _icon,
                    size: 16,
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      PhosphorIcons.check(),
                      size: 14,
                      color: scheme.primary,
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: isSelected && type != RepeatType.custom
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _IntervalRow(
                          label: _intervalLabel,
                          value: interval,
                          onChanged: onIntervalChanged,
                        ),
                        if (type == RepeatType.weekly) ...[
                          const SizedBox(height: 12),
                          Text(
                            'On',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var i = 1; i <= 7; i++)
                                _DayChip(
                                  label: const [
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                    'S',
                                  ][i - 1],
                                  selected: weekDays.contains(i),
                                  onTap: () => onToggleWeekDay(i),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.minus(), size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.plus(), size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
