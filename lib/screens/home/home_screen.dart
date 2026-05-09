import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_panel.dart';
import '../../widgets/task_list_panel.dart';
import '../../widgets/task_detail_panel.dart';

/// Home screen with adaptive 2→3 column layout:
///
/// Default (2 columns):
///   Col 1: Sidebar (264px fixed)
///   Col 2: Task list (Expanded)
///
/// When task selected (3 columns):
///   Col 1: Sidebar (264px, unchanged)
///   Col 2: Task list (Expanded)
///   Col 3: Inspector (360px, slides in from the right)
///
/// The inspector entry is 200 ms cubic-bezier(0.2, 0, 0, 1). The previous
/// task is kept rendered for the entire close animation so content slides
/// out instead of vanishing first.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectFirstList();
    });
  }

  void _selectFirstList() {
    final taskListsAsync = ref.read(taskListsNotifierProvider);
    taskListsAsync.whenData((taskLists) {
      if (taskLists.isNotEmpty) {
        final currentSelection = ref.read(selectedTaskListIdProvider);
        if (currentSelection == null) {
          ref.read(selectedTaskListIdProvider.notifier).state =
              taskLists.first.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedListId = ref.watch(selectedTaskListIdProvider);
    final taskListsAsync = ref.watch(taskListsNotifierProvider);

    // The selected task is resolved against the global task aggregate so the
    // inspector stays in sync with edits regardless of whether we're on a real
    // list or a synthetic one. Only watched on the legacy 2026 layout — the
    // 2027 redesign reads `expandedTaskIdProvider` from inside the cards.
    final selectedTask = FeatureFlags.use2027Cards
        ? null
        : ref.watch(selectedTaskProvider);

    // Listen for the first non-empty data load and auto-select the first list
    // (no postFrame; ref.listen runs after the build completes).
    ref.listen<AsyncValue<List<TaskList>>>(taskListsNotifierProvider, (
      previous,
      next,
    ) {
      next.whenData((taskLists) {
        if (taskLists.isEmpty) return;
        if (ref.read(selectedTaskListIdProvider) != null) return;
        ref.read(selectedTaskListIdProvider.notifier).state =
            taskLists.first.id;
      });
    });

    // Get list name
    String listName = 'Tasks';
    if (selectedListId != null && !selectedListId.startsWith('@')) {
      listName = taskListsAsync.when(
        data: (taskLists) {
          final found = taskLists
              .where((tl) => tl.id == selectedListId)
              .firstOrNull;
          return found?.title ?? 'Tasks';
        },
        loading: () => 'Loading...',
        error: (_, _) => 'Tasks',
      );
    } else if (selectedListId != null) {
      listName = switch (selectedListId) {
        SpecialListIds.myDay => 'My Day',
        SpecialListIds.important => 'Important',
        SpecialListIds.planned => 'Planned',
        SpecialListIds.tasks => 'Tasks',
        _ => 'Tasks',
      };
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Row(
        children: [
          // Col 1: Sidebar
          const SizedBox(width: 264, child: SidebarPanel()),
          Container(width: 1, color: scheme.outlineVariant),

          // Col 2: Task list
          Expanded(
            child: TaskListPanel(
              listId: selectedListId ?? SpecialListIds.tasks,
              listName: listName,
              onTaskSelected: (task) {
                ref.read(selectedTaskIdProvider.notifier).state = task.id;
              },
            ),
          ),

          // Col 3: Inspector — only mounted on the legacy 2026 layout.
          // The 2027 redesign expands the task inline inside the card,
          // so the inspector pane is dropped entirely (the file is kept
          // for back-compat callers and may be removed in P7).
          if (!FeatureFlags.use2027Cards)
            _InspectorSlide(
              task: selectedTask,
              listId: selectedListId ?? SpecialListIds.tasks,
              onClose: () {
                ref.read(selectedTaskIdProvider.notifier).state = null;
              },
            ),
        ],
      ),
    );
  }
}

/// 360 px inspector that animates in from the right over 200 ms with the
/// design-system curve. Keeps the previously displayed task mounted for the
/// duration of the close animation so content slides out instead of vanishing
/// before the container collapses.
class _InspectorSlide extends StatefulWidget {
  const _InspectorSlide({
    required this.task,
    required this.listId,
    required this.onClose,
  });

  final Task? task;
  final String listId;
  final VoidCallback onClose;

  @override
  State<_InspectorSlide> createState() => _InspectorSlideState();
}

class _InspectorSlideState extends State<_InspectorSlide>
    with SingleTickerProviderStateMixin {
  static const double _width = 360;
  static const Duration _entry = Duration(milliseconds: 200);
  static const Cubic _curve = Cubic(0.2, 0, 0, 1);

  late final AnimationController _controller;
  late final Animation<double> _animation;
  Task? _displayTask;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _entry,
      value: widget.task != null ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: _curve);
    _displayTask = widget.task;
  }

  @override
  void didUpdateWidget(_InspectorSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTask = widget.task;
    if (newTask != null) {
      // Either an open or a swap. Always render the freshest task; if we were
      // closed, animate in.
      if (_displayTask?.id != newTask.id || _displayTask == null) {
        setState(() => _displayTask = newTask);
      } else {
        // Same task with refreshed data — no setState; child watches its own
        // props via widget identity equality below.
        _displayTask = newTask;
      }
      if (_controller.status != AnimationStatus.completed &&
          _controller.status != AnimationStatus.forward) {
        _controller.forward();
      }
    } else if (oldWidget.task != null) {
      _controller.reverse().then((_) {
        if (mounted && widget.task == null) {
          setState(() => _displayTask = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailPanelBg =
        theme.extension<ListdSurfaces>()?.detailPanel ??
        scheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final visible = _animation.value;
        // Width-driven slide: container clips, child stays full-width pinned
        // to the right so the right edge is anchored as it slides in/out.
        return SizedBox(
          width: _width * visible,
          child: visible == 0 ? const SizedBox.shrink() : child,
        );
      },
      child: ClipRect(
        child: OverflowBox(
          maxWidth: _width,
          minWidth: _width,
          alignment: Alignment.centerRight,
          child: Container(
            width: _width,
            decoration: BoxDecoration(
              color: detailPanelBg,
              border: Border(
                left: BorderSide(color: scheme.outlineVariant, width: 1),
              ),
            ),
            child: _displayTask == null
                ? const SizedBox.shrink()
                : TaskDetailPanel(
                    // Keying by id so widget identity changes on swap and
                    // controllers reset cleanly without us threading flushes.
                    key: ValueKey<String>(_displayTask!.id),
                    task: _displayTask!,
                    listId: widget.listId,
                    onClose: widget.onClose,
                  ),
          ),
        ),
      ),
    );
  }
}
