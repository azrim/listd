import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../models/task_sort_mode.dart';
import '../providers/task_lists_provider.dart';
import '../providers/task_sort_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/ui_state_providers.dart';
import '../theme/app_theme.dart';
import 'context_menu.dart';
import 'empty_state.dart';
import 'kbd_chip.dart';
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
    case SpecialListIds.inbox:
      // Inbox: open tasks that haven't been filed into a real list.
      // Mirrors `inboxTasksProvider` from `today_provider.dart`.
      return all
          .where(
            (t) =>
                !t.isCompleted &&
                (t.taskListId.isEmpty || t.taskListId == 'inbox'),
          )
          .toList();
    case SpecialListIds.important:
      return all.where((t) => t.isStarred && !t.isCompleted).toList();
    case SpecialListIds.planned:
      return all
          .where((t) => !t.isCompleted && (t.due != null || t.reminder != null))
          .toList();
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
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 4, 48, 12),
            child: AddTaskInput(listId: listId),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              // `Up` so the gesture arena resolves before the
              // callback fires — with `Down` the parent and any
              // `InkWell` underneath co-fire on the same event,
              // double-mounting context menus when right-clicking a
              // TaskCard. See `HoverableSurface.onSecondaryTapUp`.
              onSecondaryTapUp: (details) =>
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
    final scheme = Theme.of(context).colorScheme;
    final tasks = tasksAsync.valueOrNull
        ?.where((t) => t.parentId == null)
        .toList();
    final total = tasks?.length ?? 0;
    final completed = tasks?.where((t) => t.isCompleted).length ?? 0;
    final caption = _isVirtual ? 'SMART LIST' : 'LIST';
    final showProgress = total > 0;
    final progress = total == 0 ? 0.0 : completed / total;
    final tasksLabel = total == 1 ? '1 task' : '$total tasks';

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption — sets the kind of list. SMART LIST for virtual
          // buckets (Today / Inbox / Important / Planned / All Tasks),
          // LIST for user-created lists.
          Text(
            caption,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 16 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06 * 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          // H1 24 px / 32 line / 700 weight per indigo type ramp.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  listName,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    height: 30 / 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              if (total > 0) _TaskCountChip(label: tasksLabel),
              const SizedBox(width: 8),
              Builder(
                builder: (btnCtx) => _QuietIconButton(
                  icon: PhosphorIcons.dotsThreeOutline(),
                  tooltip: 'List actions',
                  onPressed: () => _showHeaderMenu(btnCtx, ref),
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            // Progress bar — 4 px tall hairline track, indigo fill.
            // Always visible once there's at least one task; the bar
            // fills as tasks are completed.
            SizedBox(
              width: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: scheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    minHeight: 4,
                  ),
                ),
              ),
            ),
          ],
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
    final mode = ref.watch(taskSortModeProvider);
    // Apply the chosen sort mode, then sink completed tasks to the
    // bottom regardless of mode — completion-to-bottom always wins
    // over the chosen sort key. Smart buckets already filter
    // completed tasks out so this rule is a no-op there.
    mainTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return Task.compareBy(a, b, mode);
    });

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
        icon: PhosphorIcons.plus(),
        label: 'New task',
        onTap: () => _quickCreateTask(context, ref),
      ),
    ]);
  }

  /// Show the ⋯ overflow menu — a flat list of the five sort modes
  /// (current mode marked with a check) followed by a refresh row.
  /// Real submenu rendering isn't supported by `ListdContextMenu`
  /// today; flattening the modes into the same menu keeps the v1
  /// scope bounded.
  void _showHeaderMenu(BuildContext context, WidgetRef ref) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchor = Offset(
      origin.dx + box.size.width / 2,
      origin.dy + box.size.height,
    );

    final current = ref.read(taskSortModeProvider);
    showListdContextMenu(context, anchor, [
      ListdContextMenuHeader(label: 'SORT BY'),
      for (final mode in TaskSortMode.values)
        ListdContextMenuItem(
          icon: current == mode
              ? PhosphorIcons.check()
              : PhosphorIcons.dotOutline(),
          label: mode.label,
          onTap: () => ref.read(taskSortModeProvider.notifier).setMode(mode),
        ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: PhosphorIcons.arrowsClockwise(),
        label: 'Refresh',
        onTap: () => _refresh(ref),
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
            side: BorderSide(color: scheme.outline, width: 1),
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
    final spec = _emptySpecFor(listId);
    return Padding(
      padding: const EdgeInsets.all(48),
      child: EmptyState(
        icon: spec.icon,
        headline: spec.headline,
        body: spec.body,
        bodySpans: spec.bodySpans,
      ),
    );
  }

  /// Per-bucket empty-state copy + icon, sourced from the mockups.
  ///
  /// Inbox specifically mirrors `mockups/raw/07_empty_state_light.html`:
  /// inbox / tray icon, "Inbox is clear." Newsreader headline, and an
  /// italic body that interleaves text with `KbdChip`s — `Ctrl + N to
  /// add the next thing.`. Today / Important / Planned / All Tasks
  /// reuse the same kbd-chip pattern for consistency, since the mockup
  /// treats kbd as the canonical shortcut affordance.
  _EmptySpec _emptySpecFor(String id) {
    switch (id) {
      case SpecialListIds.inbox:
        return _EmptySpec(
          icon: PhosphorIcons.tray(),
          headline: 'Inbox is clear.',
          bodySpans: const [
            KbdChip('Ctrl'),
            '+',
            KbdChip('N'),
            'to add the next thing.',
          ],
        );
      case SpecialListIds.myDay:
        return _EmptySpec(
          icon: PhosphorIcons.sun(),
          headline: 'A clear day.',
          bodySpans: const [
            'Capture something with',
            KbdChip('Ctrl'),
            '+',
            KbdChip('N'),
            '— or just enjoy it.',
          ],
        );
      case SpecialListIds.important:
        return _EmptySpec(
          icon: PhosphorIcons.star(),
          headline: 'No starred tasks yet.',
          body: 'Star a task to flag it for follow-up.',
        );
      case SpecialListIds.planned:
        return _EmptySpec(
          icon: PhosphorIcons.calendarBlank(),
          headline: 'Nothing scheduled.',
          body: 'Tasks with a date or reminder land here.',
        );
      case SpecialListIds.tasks:
        return _EmptySpec(
          icon: PhosphorIcons.listChecks(),
          headline: 'No tasks anywhere.',
          body: 'Capture your first task to get started.',
        );
      default:
        return _EmptySpec(
          icon: PhosphorIcons.bookmarkSimple(),
          headline: 'Nothing here yet.',
          body: 'Capture your first task with the input above.',
        );
    }
  }
}

/// Tabular `12 tasks` chip pinned to the right of the list header.
/// Indigo-soft fill, indigo-600 fg, tabular figures.
class _TaskCountChip extends StatelessWidget {
  const _TaskCountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
          letterSpacing: 0.04,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Internal payload for [TaskListPanel._emptySpecFor].
class _EmptySpec {
  const _EmptySpec({
    required this.icon,
    required this.headline,
    this.body,
    this.bodySpans,
  });

  final IconData icon;
  final String headline;
  final String? body;
  final List<Object>? bodySpans;
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
class AddTaskInput extends ConsumerStatefulWidget {
  final String listId;

  const AddTaskInput({super.key, required this.listId});

  @override
  ConsumerState<AddTaskInput> createState() => _AddTaskInputState();
}

class _AddTaskInputState extends ConsumerState<AddTaskInput> {
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
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _focused ? scheme.surfaceContainerLow : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? scheme.primary : scheme.outline,
          width: _focused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: _isLoading
                ? CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: scheme.primary,
                  )
                : Icon(
                    PhosphorIcons.plus(),
                    size: 16,
                    color: _focused ? scheme.primary : scheme.onSurfaceVariant,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              cursorColor: scheme.primary,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 20 / 14,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Add a task',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  height: 20 / 14,
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
          const SizedBox(width: 8),
          const KbdChipRow(['Ctrl', 'N']),
        ],
      ),
    );
  }
}
