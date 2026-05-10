import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'hoverable_surface.dart';
import 'sheet_shell.dart';

/// Result returned from the Listd 2027 reminder picker.
///
///   * `null` (the dialog popped without changes) — caller leaves
///     the task's reminder untouched.
///   * `ReminderResult(value: null)` — user explicitly cleared.
///   * `ReminderResult(value: <DateTime>)` — the chosen reminder.
class ReminderResult {
  const ReminderResult(this.value);
  final DateTime? value;
}

/// Pops the Listd 2027 reminder picker — palette-shell with time-only
/// presets ("In 30 min", "In 1 h", "Tonight", "Tomorrow morning",
/// "Custom…"). Date is implied: if a [taskDue] is supplied the
/// reminder is anchored to that day, otherwise to today.
///
/// Replaces the previous date-then-time pair: most reminders are
/// "from now" so the date step is busywork.
Future<ReminderResult?> showReminderPicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? taskDue,
}) {
  return showSheetShell<ReminderResult>(
    context,
    (ctx) => _ReminderPickerSheet(initial: initial, taskDue: taskDue),
  );
}

class _ReminderPickerSheet extends StatefulWidget {
  const _ReminderPickerSheet({this.initial, this.taskDue});

  final DateTime? initial;
  final DateTime? taskDue;

  @override
  State<_ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<_ReminderPickerSheet> {
  bool _customOpen = false;
  late TimeOfDay _customTime;

  @override
  void initState() {
    super.initState();
    final base = widget.initial ?? DateTime.now().add(const Duration(hours: 1));
    _customTime = TimeOfDay.fromDateTime(base);
  }

  /// Anchor day for the reminder. Today by default; the task's due
  /// date if it's set in the future.
  DateTime get _anchorDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = widget.taskDue;
    if (due != null) {
      final dueDay = DateTime(due.year, due.month, due.day);
      if (!dueDay.isBefore(today)) return dueDay;
    }
    return today;
  }

  void _emit(DateTime value) {
    Navigator.of(context).pop(ReminderResult(value));
  }

  void _clear() {
    Navigator.of(context).pop(const ReminderResult(null));
  }

  void _emitCustom() {
    final day = _anchorDay;
    _emit(
      DateTime(
        day.year,
        day.month,
        day.day,
        _customTime.hour,
        _customTime.minute,
      ),
    );
  }

  Future<void> _showCustomTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customTime,
    );
    if (!mounted || picked == null) return;
    setState(() => _customTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tonight = DateTime(today.year, today.month, today.day, 20);
    final tomorrowMorning = DateTime(today.year, today.month, today.day + 1, 9);
    final presets = <_PresetSpec>[
      _PresetSpec(
        icon: PhosphorIcons.clock(),
        label: 'In 30 minutes',
        sub: _formatHm(now.add(const Duration(minutes: 30))),
        onTap: () => _emit(now.add(const Duration(minutes: 30))),
      ),
      _PresetSpec(
        icon: PhosphorIcons.clock(),
        label: 'In 1 hour',
        sub: _formatHm(now.add(const Duration(hours: 1))),
        onTap: () => _emit(now.add(const Duration(hours: 1))),
      ),
      _PresetSpec(
        icon: PhosphorIcons.clock(),
        label: 'In 2 hours',
        sub: _formatHm(now.add(const Duration(hours: 2))),
        onTap: () => _emit(now.add(const Duration(hours: 2))),
      ),
      _PresetSpec(
        icon: PhosphorIcons.moon(),
        label: 'Tonight',
        sub: _formatHm(tonight),
        onTap: () => _emit(tonight),
      ),
      _PresetSpec(
        icon: PhosphorIcons.sun(),
        label: 'Tomorrow morning',
        sub: '${_formatHm(tomorrowMorning)} · tomorrow',
        onTap: () => _emit(tomorrowMorning),
      ),
    ];

    return SheetShell(
      title: 'Remind me',
      icon: PhosphorIcons.bell(),
      headerActions: widget.initial == null
          ? null
          : [SheetShellClearButton(onPressed: _clear, tooltip: 'Clear')],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in presets) _PresetRow(spec: p),
            _CustomRow(
              isOpen: _customOpen,
              time: _customTime,
              onToggle: () => setState(() => _customOpen = !_customOpen),
              onPickTime: _showCustomTimePicker,
              onConfirm: _emitCustom,
              scheme: scheme,
            ),
          ],
        ),
      ),
      footer: SheetShellHintFooter(
        hint: widget.taskDue != null
            ? 'Reminder anchored to the task\u2019s due date.'
            : 'Reminder is set for today \u00B7 esc to close',
      ),
    );
  }

  String _formatHm(DateTime t) {
    final tod = TimeOfDay.fromDateTime(t);
    return tod.format(context);
  }
}

class _PresetSpec {
  const _PresetSpec({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.spec});

  final _PresetSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: HoverableSurface(
        onTap: spec.onTap,
        borderRadius: BorderRadius.circular(10),
        fillFor: (_, {required hovered, required selected}) => hovered
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest.withValues(alpha: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(spec.icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  spec.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                spec.sub,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 16 / 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomRow extends StatelessWidget {
  const _CustomRow({
    required this.isOpen,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
    required this.onConfirm,
    required this.scheme,
  });

  final bool isOpen;
  final TimeOfDay time;
  final VoidCallback onToggle;
  final VoidCallback onPickTime;
  final VoidCallback onConfirm;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HoverableSurface(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            fillFor: (_, {required hovered, required selected}) => hovered
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainerHighest.withValues(alpha: 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.timer(),
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Custom\u2026',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen
                        ? PhosphorIcons.caretUp()
                        : PhosphorIcons.caretDown(),
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: onPickTime,
                          icon: Icon(PhosphorIcons.clock(), size: 16),
                          label: Text(time.format(context)),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: onConfirm,
                          child: const Text('Set reminder'),
                        ),
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
