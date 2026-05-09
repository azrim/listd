import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../widgets/task_list_panel.dart';

/// User-list canvas — `/list/:id`.
///
/// Renders a single column inside the 2027 `AppShell` (top bar + hidden
/// sidebar drawer). The card list and inline expand are owned by
/// [TaskListPanel] / `TaskCard`; this screen is a thin wrapper that
/// reads the `:id` path parameter, mirrors it onto
/// `selectedTaskListIdProvider` so other surfaces (capture sheet,
/// command palette) target the correct list, and resolves the list's
/// display name.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeId = GoRouterState.of(context).pathParameters['id'];
    final taskListsAsync = ref.watch(taskListsNotifierProvider);

    // Mirror the route param onto the legacy provider after the frame
    // commits so capture flows keep targeting the active list. Skipping
    // the write when nothing changed prevents a rebuild storm.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final current = ref.read(selectedTaskListIdProvider);
      if (current != routeId) {
        ref.read(selectedTaskListIdProvider.notifier).state = routeId;
      }
    });

    final listId = routeId ?? SpecialListIds.tasks;
    final listName = _resolveName(listId, taskListsAsync);

    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: TaskListPanel(listId: listId, listName: listName),
    );
  }

  String _resolveName(String listId, AsyncValue<List<TaskList>> async) {
    if (listId.startsWith('@')) {
      return switch (listId) {
        SpecialListIds.myDay => 'My Day',
        SpecialListIds.important => 'Important',
        SpecialListIds.planned => 'Planned',
        SpecialListIds.tasks => 'Tasks',
        _ => 'Tasks',
      };
    }
    return async.when(
      data: (lists) =>
          lists.where((l) => l.id == listId).firstOrNull?.title ?? 'Tasks',
      loading: () => 'Loading…',
      error: (_, _) => 'Tasks',
    );
  }
}
