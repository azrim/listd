import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../providers/overlays_provider.dart';
import '../providers/task_lists_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_theme.dart';
import '../utils/capture_parser.dart';

/// Listd 2027 P6 capture sheet.
///
/// Opens via Ctrl + N. Sliding sheet from the top (~520 px wide,
/// auto-height). One borderless input + a live "preview chip" row that
/// shows the parsed `due`, tags, list hint, and star marker as the
/// user types. Enter commits.
///
/// Optimistic — writes to Drift immediately, dismisses, lets
/// `TaskSyncService.scheduleSync()` push to Supabase in the background.
class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  CaptureResult _preview = const CaptureResult(title: '');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onChanged() {
    setState(() {
      _preview = CaptureParser.parse(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final result = _preview;
    if (result.title.trim().isEmpty) return;

    // Resolve target list. Use the currently selected list, or the
    // first user list, or the synthetic "tasks" inbox as a fallback.
    final selected = ref.read(selectedTaskListIdProvider);
    final lists = ref.read(taskListsNotifierProvider).valueOrNull ?? const [];
    final listId = (selected != null && !selected.startsWith('@'))
        ? selected
        : (lists.isNotEmpty ? lists.first.id : SpecialListIds.tasks);

    final task = Task(
      id: const Uuid().v4(),
      taskListId: listId,
      title: result.title,
      due: result.due,
      isStarred: result.isStarred,
      updated: DateTime.now(),
    );

    await ref.read(tasksNotifierProvider(listId).notifier).createTask(task);
    if (!mounted) return;
    ref.read(captureSheetOpenProvider.notifier).state = false;
  }

  void _close() {
    ref.read(captureSheetOpenProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.panel ?? scheme.surface;

    return Center(
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Material(
            color: cardBg,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant, width: 1),
                boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.plus(),
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Shortcuts(
                            shortcuts: const {
                              SingleActivator(LogicalKeyboardKey.escape):
                                  _CloseIntent(),
                            },
                            child: Actions(
                              actions: <Type, Action<Intent>>{
                                _CloseIntent: CallbackAction<_CloseIntent>(
                                  onInvoke: (_) => _close(),
                                ),
                              },
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  height: 22 / 16,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Capture a task — try "tomorrow at 3 #errands !"',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 16,
                                    height: 22 / 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (_) => _commit(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasPreviewChips(_preview))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _buildChips(_preview, scheme),
                      ),
                    ),
                  // AI suggestion slot · spatial reservation per
                  // 03_components.md §9. Hidden until the user types
                  // ≥ 4 characters. Today the slot is silent;
                  // upcoming iterations populate it with model-driven
                  // due-date / list / star inferences. Reserving the
                  // surface now means we don't redesign the sheet
                  // when AI lands.
                  if (_controller.text.trim().length >= 4)
                    _AiSuggestionsSlot(scheme: scheme),
                  Container(height: 1, color: scheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                    child: Row(
                      children: [
                        Text(
                          'Enter to capture · Esc to dismiss',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 16 / 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _commit,
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasPreviewChips(CaptureResult r) =>
      r.due != null || r.isStarred || r.listHint != null || r.tags.isNotEmpty;

  List<Widget> _buildChips(CaptureResult r, ColorScheme scheme) {
    final chips = <Widget>[];
    if (r.due != null) {
      chips.add(
        _PreviewChip(
          icon: PhosphorIcons.calendar(),
          label: DateFormat('EEE MMM d, h:mm a').format(r.due!),
          scheme: scheme,
        ),
      );
    }
    if (r.isStarred) {
      chips.add(
        _PreviewChip(
          icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
          label: 'Star',
          scheme: scheme,
          accent: true,
        ),
      );
    }
    if (r.listHint != null) {
      chips.add(
        _PreviewChip(
          icon: PhosphorIcons.bookmark(),
          label: '@${r.listHint}',
          scheme: scheme,
        ),
      );
    }
    for (final t in r.tags) {
      chips.add(
        _PreviewChip(icon: PhosphorIcons.hash(), label: t, scheme: scheme),
      );
    }
    return chips;
  }
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.scheme,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final fg = accent ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
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
    );
  }
}

/// `✦ SUGGESTIONS` panel — three keyboard-driven quick actions per
/// `08_capture_sheet_light.png`. Each row is a label + keybind chip.
/// Hidden until the user types ≥ 4 characters.
class _AiSuggestionsSlot extends StatelessWidget {
  const _AiSuggestionsSlot({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.sparkle(), size: 12, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'SUGGESTIONS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SuggestionRow(
            scheme: scheme,
            label: 'Add to today',
            keys: const ['↩'],
          ),
          _SuggestionRow(
            scheme: scheme,
            label: 'Add and stay',
            keys: const ['⌥', '↩'],
          ),
          _SuggestionRow(
            scheme: scheme,
            label: 'Add and star',
            keys: const ['⇧', '↩'],
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.scheme,
    required this.label,
    required this.keys,
  });

  final ColorScheme scheme;
  final String label;
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
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
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _KeyChip(label: keys[i], scheme: scheme),
          ],
        ],
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.04,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
