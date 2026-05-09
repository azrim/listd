import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that lists every user-owned `TaskList` so the caller
/// can pick one. Returns the selected `TaskList` or `null` on cancel.
///
/// Used for "Move to list…" right-click flows. The currently-owning
/// list (if any) is highlighted with the indigo accent and skipped from
/// the navigable rows.
Future<TaskList?> showListPicker(
  BuildContext context, {
  String? excludeListId,
  String title = 'Move to list',
}) {
  return showModalBottomSheet<TaskList?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) =>
        _ListPickerSheet(excludeListId: excludeListId, title: title),
  );
}

class _ListPickerSheet extends ConsumerWidget {
  const _ListPickerSheet({this.excludeListId, required this.title});

  final String? excludeListId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final lists = ref.watch(taskListsNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: surfaces?.panel ?? scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 22 / 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: lists.when(
                  data: (allLists) {
                    final filtered = allLists
                        .where((l) => l.id != excludeListId)
                        .toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No other lists',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final l = filtered[i];
                        return _ListRow(
                          taskList: l,
                          onTap: () => Navigator.of(ctx).pop(l),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load: $e',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: scheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListRow extends StatefulWidget {
  const _ListRow({required this.taskList, required this.onTap});

  final TaskList taskList;
  final VoidCallback onTap;

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? scheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.bookmark(),
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.taskList.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
