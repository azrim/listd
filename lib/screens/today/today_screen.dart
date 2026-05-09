import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../providers/today_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/calendar_strip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_list_panel.dart';

/// Listd 2027 · Indigo Today canvas.
///
/// Per `docs/redesign/2027-indigo/mockups/01_today_light.png` the
/// canvas sits directly on the indigo backplate — no outer card or
/// shadow. Layout, top-to-bottom:
///
///   * Newsreader display headline ("Today, Sat May 9").
///   * Slate meta line ("May 9 · Week 19").
///   * 7-day calendar strip — selected day is a solid indigo capsule
///     with stacked DOW / DATE.
///   * Capture row ("+ Add a task" + Ctrl + N keybind chip).
///   * Task rows (TaskCard list).
///
/// Tasks come from `todayTasksProvider` (smart bucket per UX plan §1).
/// Selecting a different day on the strip filters the list to tasks
/// due that day; clicking the headline returns to "today".
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);

    // Mirror Today onto the active list provider so Ctrl + N capture
    // (which dispatches into the selected list's `tasksNotifierProvider`)
    // lands tasks in the right bucket. We still resolve the actual
    // target list inside `AddTaskInput` for virtual buckets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(selectedTaskListIdProvider);
      if (current != SpecialListIds.myDay) {
        ref.read(selectedTaskListIdProvider.notifier).state =
            SpecialListIds.myDay;
      }
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selected.year == now.year &&
        _selected.month == now.month &&
        _selected.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.extension<ListdTypography>();

    final todayAsync = ref.watch(todayTasksProvider);
    final headline = _isToday
        ? 'Today, ${DateFormat('EEE MMM d').format(_selected)}'
        : DateFormat('EEEE, MMM d').format(_selected);
    final weekNumber = _isoWeekNumber(_selected);
    final metaLine =
        '${DateFormat('MMM d').format(_selected)} · Week $weekNumber';

    return Material(
      type: MaterialType.canvas,
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Headline + meta line — Newsreader display, slate meta.
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 4),
            child: GestureDetector(
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _selected = DateTime(now.year, now.month, now.day);
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style:
                        typography?.displaySerif ??
                        GoogleFonts.newsreader(
                          fontSize: 36,
                          height: 44 / 36,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.72,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metaLine,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Calendar strip — full-width on the canvas, bleeds the
          // indigo today capsule per mockup.
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
            child: CalendarStrip(
              selectedDay: _selected,
              onDaySelected: (d) => setState(() => _selected = d),
            ),
          ),
          // Capture row — same `AddTaskInput` widget as the list panel
          // so the Ctrl + N keybind chip + hairline border treatment
          // stays consistent across canvases.
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
            child: AddTaskInput(listId: SpecialListIds.myDay),
          ),
          Expanded(
            child: todayAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Couldn\'t load Today: $e',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
              data: (tasks) {
                final filtered = _isToday
                    ? tasks
                    : _filterByDay(tasks, _selected);
                if (filtered.isEmpty) {
                  return _EmptyState(isToday: _isToday);
                }
                return _buildList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Task> tasks) {
    final expandedId = ref.watch(expandedTaskIdProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          key: ValueKey<String>(task.id),
          task: task,
          listId: task.taskListId,
          isExpanded: expandedId == task.id,
          isSelected: selectedTaskId == task.id,
          onToggleExpand: () {
            final notifier = ref.read(expandedTaskIdProvider.notifier);
            notifier.state = expandedId == task.id ? null : task.id;
            ref.read(selectedTaskIdProvider.notifier).state = task.id;
          },
        );
      },
    );
  }

  /// ISO 8601 week number for [date] — used in the meta line under
  /// the Today headline (e.g. `May 9 · Week 19`).
  int _isoWeekNumber(DateTime date) {
    // Add 4 days then divide by 7 to land on the ISO week — this is
    // the standard "Thursday in the same ISO week" trick.
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final weekday = date.weekday; // 1 = Mon, 7 = Sun.
    return ((dayOfYear - weekday + 10) / 7).floor();
  }

  List<Task> _filterByDay(List<Task> tasks, DateTime day) {
    return tasks.where((t) {
      if (t.due == null) return false;
      return t.due!.year == day.year &&
          t.due!.month == day.month &&
          t.due!.day == day.day;
    }).toList();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: EmptyState(
        icon: PhosphorIcons.sun(),
        headline: isToday ? 'A clear day.' : 'Nothing here.',
        body: isToday
            ? 'Capture something with Ctrl + N — or just enjoy it.'
            : 'Nothing scheduled for this day.',
      ),
    );
  }
}
