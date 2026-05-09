import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task.dart';

/// Bottom sheet that lets the user pick a repeat schedule for a task.
/// Returns:
///   * `null` — sheet was dismissed without changes
///   * a `RepeatConfig?` wrapped in a `RepeatResult` — the user
///     explicitly committed a value (which may be `null` to clear).
class RepeatResult {
  const RepeatResult(this.value);
  final RepeatConfig? value;
}

Future<RepeatResult?> showRepeatPicker(
  BuildContext context, {
  RepeatConfig? initial,
}) {
  return showModalBottomSheet<RepeatResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RepeatPickerSheet(initial: initial),
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
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repeat',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in RepeatType.values)
                    _TypeChip(
                      label: _labelFor(t),
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_type != RepeatType.custom)
                _IntervalRow(
                  label: _intervalLabel(_type),
                  value: _interval,
                  onChanged: (v) => setState(() => _interval = v),
                ),
              if (_type == RepeatType.weekly) ...[
                const SizedBox(height: 16),
                Text(
                  'On',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 1; i <= 7; i++)
                      _DayChip(
                        label: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i - 1],
                        selected: _weekDays.contains(i),
                        onTap: () => setState(() {
                          if (_weekDays.contains(i)) {
                            _weekDays.remove(i);
                          } else {
                            _weekDays.add(i);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _clear,
                    child: const Text("Don't repeat"),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _commit, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(RepeatType t) => switch (t) {
    RepeatType.daily => 'Daily',
    RepeatType.weekly => 'Weekly',
    RepeatType.monthly => 'Monthly',
    RepeatType.yearly => 'Yearly',
    RepeatType.custom => 'Custom',
  };

  String _intervalLabel(RepeatType t) => switch (t) {
    RepeatType.daily => 'Every N days',
    RepeatType.weekly => 'Every N weeks',
    RepeatType.monthly => 'Every N months',
    RepeatType.yearly => 'Every N years',
    RepeatType.custom => 'Every N',
  };
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(PhosphorIcons.check(), size: 14, color: scheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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
