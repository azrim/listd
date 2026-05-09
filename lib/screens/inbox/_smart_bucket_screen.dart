import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ui_state_providers.dart';
import '../../widgets/task_list_panel.dart';

/// Shared canvas for smart buckets that don't need a calendar strip
/// (Inbox / Important / Planned / All Tasks).
///
/// Renders the same `TaskListPanel` chrome as `/list/:id` (LIST /
/// SMART LIST caption + H1 + indigo progress bar + tasks-count pill +
/// ⋯ menu, capture row underneath, then the task rows). The screen no
/// longer wraps its content in a 20-px-radius card with shadow — per
/// the indigo mockups every canvas sits directly on the backplate.
class SmartBucketScreen extends ConsumerWidget {
  // ignore: prefer_const_constructors_in_immutables
  SmartBucketScreen({super.key, required this.title, required this.virtualId});

  final String title;

  /// One of `SpecialListIds.{inbox, important, planned, tasks}`.
  final String virtualId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mirror the virtual id onto the legacy provider so capture flows
    // (Ctrl + N) target a sane list when fired from a smart bucket.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final current = ref.read(selectedTaskListIdProvider);
      if (current != virtualId) {
        ref.read(selectedTaskListIdProvider.notifier).state = virtualId;
      }
    });

    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.canvas,
      color: scheme.surface,
      child: TaskListPanel(listId: virtualId, listName: title),
    );
  }
}
