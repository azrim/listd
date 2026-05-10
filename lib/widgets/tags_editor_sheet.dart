import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/tasks_provider.dart';
import 'hoverable_surface.dart';
import 'sheet_shell.dart';

/// Pops the Listd 2027 tags editor — palette-shell with a search /
/// add input in the header and two list sections beneath it: applied
/// tags (with a remove icon) and suggested tags (sourced from
/// [allTasksProvider]).
///
/// Returns the updated tag list, or `null` on cancel.
Future<List<String>?> showTagsEditor(
  BuildContext context, {
  required List<String> initial,
}) {
  return showSheetShell<List<String>>(
    context,
    (ctx) => _TagsEditorSheet(initial: initial),
  );
}

class _TagsEditorSheet extends ConsumerStatefulWidget {
  const _TagsEditorSheet({required this.initial});
  final List<String> initial;

  @override
  ConsumerState<_TagsEditorSheet> createState() => _TagsEditorSheetState();
}

class _TagsEditorSheetState extends ConsumerState<_TagsEditorSheet> {
  late List<String> _tags;
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.initial);
    _input.addListener(() {
      final next = _input.text;
      if (next != _query) setState(() => _query = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  }

  void _add([String? raw]) {
    final tag = _normalize(raw ?? _input.text);
    if (tag.isEmpty) return;
    if (!_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _input.clear();
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
  }

  /// All tags used elsewhere in the app, minus the ones already on
  /// this task and minus those that don't match the live query.
  List<String> _suggestions() {
    final all = ref.watch(allTasksProvider).valueOrNull ?? const [];
    final unique = <String>{};
    for (final t in all) {
      for (final tag in t.tags) {
        unique.add(tag);
      }
    }
    final q = _normalize(_query).toLowerCase();
    final list =
        unique
            .where((tag) => !_tags.contains(tag))
            .where((tag) => q.isEmpty || tag.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final suggestions = _suggestions();
    final canCreate =
        _normalize(_query).isNotEmpty &&
        !_tags.contains(_normalize(_query)) &&
        !suggestions.contains(_normalize(_query));

    return SheetShell(
      title: 'Tags',
      icon: PhosphorIcons.hash(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _input,
              focusNode: _focus,
              onSubmitted: (_) => _add(),
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 20 / 14,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search or add a tag…',
                prefixIcon: Icon(PhosphorIcons.hash(), size: 16),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canCreate)
                      _Row(
                        leading: Icon(
                          PhosphorIcons.plusCircle(),
                          size: 16,
                          color: scheme.primary,
                        ),
                        label: 'Add "${_normalize(_query)}"',
                        labelColor: scheme.primary,
                        onTap: () => _add(),
                      ),
                    if (_tags.isNotEmpty)
                      _SectionLabel(label: 'Applied (${_tags.length})'),
                    for (final tag in _tags)
                      _Row(
                        leading: Icon(
                          PhosphorIcons.tag(),
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        label: tag,
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: Icon(PhosphorIcons.x(), size: 14),
                          color: scheme.onSurfaceVariant,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _remove(tag),
                        ),
                      ),
                    if (suggestions.isNotEmpty)
                      _SectionLabel(label: 'Suggested'),
                    for (final tag in suggestions)
                      _Row(
                        leading: Icon(
                          PhosphorIcons.hash(),
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        label: tag,
                        onTap: () => _add(tag),
                      ),
                    if (_tags.isEmpty &&
                        suggestions.isEmpty &&
                        _normalize(_query).isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                        child: Text(
                          'No tags yet — type a name and press Enter.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 18 / 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      footer: SheetShellActionFooter(
        trailing: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_tags),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.label,
    this.trailing,
    this.onTap,
    this.labelColor,
  });

  final Widget leading;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: HoverableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        fillFor: (_, {required hovered, required selected}) => hovered
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest.withValues(alpha: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor ?? scheme.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
