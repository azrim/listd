import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../utils/url_detector.dart';
import 'inline_edit_field.dart';

/// Inline editor for `Task.steps`. Renders each step as a circular
/// checkbox + editable label, with a trailing link icon (one-click to
/// open in browser) when the step text contains a URL.
///
/// The editor is **height-capped** by the caller so a task with 30 steps
/// still leaves the surrounding card's expanded body at a reasonable
/// size — we wrap an internally-scrolling `ListView` plus a fixed
/// "Add step" row at the bottom.
///
/// Mutations are debounced 400 ms per step and **flushed hard** on
/// dispose so partial edits aren't lost. Callers receive the new step
/// list via [onStepsChanged]; persisting that list to Drift / Supabase
/// is the parent's responsibility.
class TaskStepsEditor extends StatefulWidget {
  const TaskStepsEditor({
    super.key,
    required this.steps,
    required this.onStepsChanged,
    this.maxHeight = 220,
  });

  final List<TaskStep> steps;
  final ValueChanged<List<TaskStep>> onStepsChanged;
  final double maxHeight;

  @override
  State<TaskStepsEditor> createState() => _TaskStepsEditorState();
}

class _TaskStepsEditorState extends State<TaskStepsEditor> {
  static const Duration _debounce = Duration(milliseconds: 400);
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _newStep = TextEditingController();
  Timer? _flushTimer;

  @override
  void didUpdateWidget(covariant TaskStepsEditor old) {
    super.didUpdateWidget(old);
    // Keep TextEditingControllers in lockstep with new step ids; drop
    // controllers for steps that are no longer present.
    final currentIds = widget.steps.map((s) => s.id).toSet();
    _controllers.removeWhere((id, c) {
      if (!currentIds.contains(id)) {
        c.dispose();
        return true;
      }
      return false;
    });
    for (final step in widget.steps) {
      final c = _controllers[step.id];
      if (c == null) {
        _controllers[step.id] = TextEditingController(text: step.title);
      } else if (c.text != step.title && !c.selection.isValid) {
        c.text = step.title;
      }
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _flushNow();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _newStep.dispose();
    super.dispose();
  }

  TextEditingController _ctrlFor(TaskStep s) {
    return _controllers.putIfAbsent(
      s.id,
      () => TextEditingController(text: s.title),
    );
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_debounce, _flushNow);
  }

  void _flushNow() {
    _flushTimer = null;
    final next = <TaskStep>[];
    var dirty = false;
    for (final step in widget.steps) {
      final text = _controllers[step.id]?.text ?? step.title;
      if (text != step.title) dirty = true;
      next.add(step.copyWith(title: text));
    }
    if (dirty) widget.onStepsChanged(next);
  }

  void _toggle(TaskStep step) {
    final next = widget.steps
        .map(
          (s) => s.id == step.id ? s.copyWith(isCompleted: !s.isCompleted) : s,
        )
        .toList();
    widget.onStepsChanged(next);
  }

  void _delete(TaskStep step) {
    _controllers[step.id]?.dispose();
    _controllers.remove(step.id);
    final next = widget.steps.where((s) => s.id != step.id).toList();
    widget.onStepsChanged(next);
  }

  void _addStep() {
    final text = _newStep.text.trim();
    if (text.isEmpty) return;
    final next = [
      ...widget.steps,
      TaskStep(
        id: const Uuid().v4(),
        title: text,
        position: widget.steps.length,
      ),
    ];
    _newStep.clear();
    widget.onStepsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.steps.length,
              itemBuilder: (context, i) {
                final step = widget.steps[i];
                return _StepRow(
                  key: ValueKey(step.id),
                  step: step,
                  controller: _ctrlFor(step),
                  onChanged: (_) => _scheduleFlush(),
                  onSubmit: _flushNow,
                  onToggle: () => _toggle(step),
                  onDelete: () => _delete(step),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  PhosphorIcons.plus(),
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: InlineEditField(
                  controller: _newStep,
                  onSubmitted: (_) => _addStep(),
                  placeholder: 'Add step',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  const _StepRow({
    super.key,
    required this.step,
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskStep step;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urls = extractUrls(widget.controller.text);
    final completed = widget.step.isCompleted;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _StepCheckbox(completed: completed, onTap: widget.onToggle),
            const SizedBox(width: 12),
            Expanded(
              child: InlineEditField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmit(),
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                  color: completed ? scheme.outline : scheme.onSurface,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (urls.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: prettyHost(urls.first),
                icon: Icon(
                  PhosphorIcons.arrowSquareOut(),
                  size: 16,
                  color: scheme.primary,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                onPressed: () async {
                  final ok = await launchInBrowser(urls.first);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Couldn't open ${urls.first}")),
                    );
                  }
                },
              ),
            ],
            if (_hovered)
              IconButton(
                tooltip: 'Delete step',
                icon: Icon(
                  PhosphorIcons.x(),
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
                onPressed: widget.onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// 16 px checkbox tuned for the steps row — slightly tighter than the
/// 20 px primary card checkbox so a row of 6 steps doesn't dominate the
/// expanded body.
class _StepCheckbox extends StatelessWidget {
  const _StepCheckbox({required this.completed, required this.onTap});
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: completed ? scheme.primary : scheme.outline,
            width: 1.25,
          ),
        ),
        alignment: Alignment.center,
        child: completed
            ? Icon(Icons.check, size: 11, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}
