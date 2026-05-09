import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../providers/task_lists_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_theme.dart';
import 'context_menu.dart';
import 'task_card.dart';

/// Filter the aggregate task stream into the slice that belongs to a virtual
/// list (My Day / Important / Planned / Tasks).
List<Task> _filterForVirtualList(List<Task> all, String listId) {
  final today = DateTime.now();
  bool sameDay(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;

  switch (listId) {
    case SpecialListIds.myDay:
      return all.where((t) => t.due != null && sameDay(t.due!)).toList();
    case SpecialListIds.important:
      return all.where((t) => t.isStarred).toList();
    case SpecialListIds.planned:
      return all.where((t) => t.due != null).toList();
    case SpecialListIds.tasks:
      return all;
    default:
      return all;
  }
}

/// Pick the list that "Add a task" on a virtual screen should write to.
/// Prefers the user's default list, then falls back to the first list.
TaskList? _resolveTargetList(List<TaskList> lists) {
  if (lists.isEmpty) return null;
  final defaults = lists.where((l) => l.isDefault);
  return defaults.isNotEmpty ? defaults.first : lists.first;
}

/// Listd 2027 list pane.
///
/// Renders a section header (display title + refresh icon), an inline
/// capture input for real (non-virtual) lists, and the list of
/// `TaskCard` islands. The pane is the only owner of the list-level
/// header chrome; the cards own their own surface.
class TaskListPanel extends ConsumerWidget {
  final String listId;
  final String listName;
  final Function(Task)? onTaskSelected;

  const TaskListPanel({
    super.key,
    required this.listId,
    required this.listName,
    this.onTaskSelected,
  });

  bool get _isVirtual => listId.startsWith('@');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = _isVirtual
        ? ref
              .watch(allTasksProvider)
              .whenData((all) => _filterForVirtualList(all, listId))
        : ref.watch(tasksNotifierProvider(listId));
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, ref, tasksAsync),
          if (!_isVirtual)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _AddTaskInput(listId: listId),
            )
          else
            const SizedBox(height: 4),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapDown: (details) =>
                  _showEmptyAreaMenu(context, ref, details.globalPosition),
              child: tasksAsync.when(
                data: (tasks) =>
                    _buildContent(context, ref, tasks, selectedTaskId),
                loading: () => const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                error: (e, _) => _buildError(context, ref, e),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger a fresh fetch. Virtual lists ask every real list to resync,
  /// since the aggregate is computed from those.
  Future<void> _refresh(WidgetRef ref) async {
    if (!_isVirtual) {
      await ref.read(tasksNotifierProvider(listId).notifier).syncFromRemote();
      return;
    }
    final lists = ref.read(taskListsNotifierProvider).valueOrNull ?? const [];
    await Future.wait(
      lists.map(
        (l) => ref.read(tasksNotifierProvider(l.id).notifier).syncFromRemote(),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Task>> tasksAsync,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = tasksAsync.valueOrNull
        ?.where((t) => t.parentId == null && !t.isCompleted)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    listName,
                    style: theme.textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 22 / 15,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _QuietIconButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    String? selectedTaskId,
  ) {
    final mainTasks = tasks.where((t) => t.parentId == null).toList();

    if (mainTasks.isEmpty) {
      return _buildEmptyState(context);
    }

    final scheme = Theme.of(context).colorScheme;

    // 2027 — render TaskCard islands. No separators (cards are their
    // own surface) and tap toggles inline expand instead of mounting
    // an inspector pane.
    final expandedId = ref.watch(expandedTaskIdProvider);
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      color: scheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: mainTasks.length,
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          final ownerListId = task.taskListId;
          return TaskCard(
            key: ValueKey<String>(task.id),
            task: task,
            listId: ownerListId,
            isExpanded: expandedId == task.id,
            isSelected: selectedTaskId == task.id,
            onToggleExpand: () {
              final notifier = ref.read(expandedTaskIdProvider.notifier);
              notifier.state = expandedId == task.id ? null : task.id;
              ref.read(selectedTaskIdProvider.notifier).state = task.id;
              onTaskSelected?.call(task);
            },
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Couldn\'t load tasks',
            style: theme.textTheme.titleMedium?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 8),
          Text('$error', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _refresh(ref),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showEmptyAreaMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
  ) {
    showListdContextMenu(context, globalPosition, [
      ListdContextMenuItem(
        icon: Icons.add,
        label: 'New task',
        onTap: () => _quickCreateTask(context, ref),
      ),
    ]);
  }

  Future<void> _quickCreateTask(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final title = await _promptForTitle(context);
    if (title == null || title.trim().isEmpty) return;

    String targetListId = listId;
    DateTime? defaultDue;
    bool defaultStarred = false;
    if (listId.startsWith('@')) {
      final lists =
          ref.read(taskListsNotifierProvider).valueOrNull ?? const <TaskList>[];
      final target = _resolveTargetList(lists);
      if (target == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Create a list first to add tasks here'),
          ),
        );
        return;
      }
      targetListId = target.id;
      if (listId == SpecialListIds.myDay) {
        final now = DateTime.now();
        defaultDue = DateTime(now.year, now.month, now.day);
      } else if (listId == SpecialListIds.important) {
        defaultStarred = true;
      }
    }

    final task = Task(
      id: const Uuid().v4(),
      title: title.trim(),
      updated: DateTime.now(),
      taskListId: targetListId,
      due: defaultDue,
      isStarred: defaultStarred,
    );
    await ref
        .read(tasksNotifierProvider(targetListId).notifier)
        .createTask(task);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Task added'),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  /// Inline single-line dialog for the empty-area "New task" right-click
  /// flow. Returns the entered title or `null` on cancel.
  Future<String?> _promptForTitle(BuildContext context) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final surfaces = theme.extension<ListdSurfaces>();
        return Dialog(
          backgroundColor: surfaces?.panel ?? scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New task',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    focusNode: focus,
                    cursorColor: scheme.primary,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                    onSubmitted: (v) => Navigator.of(ctx).pop(v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(controller.text),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nothing here yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Capture your first task with the input above.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 32×32 quiet icon button — no border, hover fills `surface-sunken`.
class _QuietIconButton extends StatelessWidget {
  const _QuietIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppTheme.controlHeight,
      height: AppTheme.controlHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Quiet capture input. 32 px tall, no fill, single 1 px hairline at the
/// bottom that swaps to accent + 2 px on focus. Reads like an underlined
/// native field — far closer to the rest of the inspector's hairline
/// vocabulary than the chunky filled rectangle this used to be.
class _AddTaskInput extends ConsumerStatefulWidget {
  final String listId;

  const _AddTaskInput({required this.listId});

  @override
  ConsumerState<_AddTaskInput> createState() => _AddTaskInputState();
}

class _AddTaskInputState extends ConsumerState<_AddTaskInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _focused) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isLoading) return;

    String targetListId = widget.listId;
    DateTime? defaultDue;
    bool defaultStarred = false;

    if (widget.listId.startsWith('@')) {
      final lists =
          ref.read(taskListsNotifierProvider).valueOrNull ?? const <TaskList>[];
      final target = _resolveTargetList(lists);
      if (target == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create a list first to add tasks here'),
            ),
          );
        }
        return;
      }
      targetListId = target.id;
      if (widget.listId == SpecialListIds.myDay) {
        final now = DateTime.now();
        defaultDue = DateTime(now.year, now.month, now.day);
      } else if (widget.listId == SpecialListIds.important) {
        defaultStarred = true;
      }
    }

    setState(() => _isLoading = true);
    try {
      final id = const Uuid().v4();
      final newTask = Task(
        id: id,
        title: title,
        updated: DateTime.now(),
        taskListId: targetListId,
        due: defaultDue,
        isStarred: defaultStarred,
      );
      await ref
          .read(tasksNotifierProvider(targetListId).notifier)
          .createTask(newTask);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Task added'),
              duration: Duration(milliseconds: 1400),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Could not add task: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: AppTheme.controlHeight + 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _focused ? scheme.primary : scheme.outlineVariant,
              width: _focused ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: _isLoading
                  ? CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: scheme.primary,
                    )
                  : Icon(
                      Icons.add,
                      size: 14,
                      color: _focused
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: scheme.primary,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 22 / 15,
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a task',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    height: 22 / 15,
                    color: scheme.outline,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _addTask(),
                enabled: !_isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
