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

/// Listd 2026 list pane.
///
/// The list pane is the bright surface and reads as a single sheet of
/// paper. The header is a 22 px H2 title plus a quiet refresh icon.
/// Below it sits the borderless capture input on `surface-sunken`.
/// Rows are 44 px tall with hairline separators between them — no
/// rounded chips, no shadows.
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

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      color: scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mainTasks.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          // Mutations always target the task's real owning list, not the
          // virtual screen the user happens to be viewing.
          final ownerListId = task.taskListId;
          return _TaskRow(
            task: task,
            isSelected: selectedTaskId == task.id,
            onTap: () {
              ref.read(selectedTaskIdProvider.notifier).state = task.id;
              onTaskSelected?.call(task);
            },
            onToggle: () => ref
                .read(tasksNotifierProvider(ownerListId).notifier)
                .toggleComplete(task),
            onDelete: () => _confirmDelete(context, ref, task),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(tasksNotifierProvider(task.taskListId).notifier)
          .deleteTask(task.id);
    }
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

/// 44 px task row — 18 px circular checkbox + title + meta cluster +
/// optional star. Hover fills `surface-sunken`. Selected gets
/// `accent-soft` fill + 2 px accent left bar.
class _TaskRow extends StatefulWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const _TaskRow({
    required this.task,
    this.isSelected = false,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final task = widget.task;
    final isSelected = widget.isSelected;

    Color rowColor;
    if (isSelected) {
      rowColor = scheme.primaryContainer;
    } else if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else {
      rowColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _Checkbox(
                        completed: task.isCompleted,
                        onTap: widget.onToggle,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 22 / 15,
                            fontWeight: FontWeight.w400,
                            color: task.isCompleted
                                ? scheme.outline
                                : scheme.onSurface,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: scheme.outline,
                            decorationThickness: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (task.due != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(task.due!),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (task.isStarred) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    return '${date.month}/${date.day}';
  }
}

/// 18 px circular checkbox. Empty: 1 px outline. Completed: filled
/// accent + white check.
class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: completed ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
        ),
        child: completed
            ? Icon(Icons.check, size: 12, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}

/// Borderless capture input — sits on `surface-sunken`, 32 px tall,
/// 8 px radius, no border. Focus ring: 2 px accent outset on focus.
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: AppTheme.controlHeight,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        border: Border.all(
          color: _focused ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (_isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: scheme.primary,
              ),
            )
          else
            Icon(Icons.add, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
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
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _addTask(),
              enabled: !_isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
