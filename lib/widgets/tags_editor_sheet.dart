import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet that lets the user add / remove tags. Returns the
/// updated tag list, or `null` on cancel.
Future<List<String>?> showTagsEditor(
  BuildContext context, {
  required List<String> initial,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TagsEditorSheet(initial: initial),
  );
}

class _TagsEditorSheet extends StatefulWidget {
  const _TagsEditorSheet({required this.initial});
  final List<String> initial;

  @override
  State<_TagsEditorSheet> createState() => _TagsEditorSheetState();
}

class _TagsEditorSheetState extends State<_TagsEditorSheet> {
  late List<String> _tags;
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.initial);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _input.text.trim();
    if (raw.isEmpty) return;
    // Strip a leading '#' if the user typed one.
    final tag = raw.startsWith('#') ? raw.substring(1) : raw;
    if (tag.isEmpty) return;
    if (!_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _input.clear();
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
                'Tags',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (_tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tags yet — type below and press enter.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 18 / 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in _tags)
                      _TagPill(tag: tag, onRemove: () => _remove(tag)),
                  ],
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _input,
                onSubmitted: (_) => _add(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 20 / 14,
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a tag (no #)',
                  prefixIcon: Icon(PhosphorIcons.hash(), size: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_tags),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$tag',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(PhosphorIcons.x(), size: 12, color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
