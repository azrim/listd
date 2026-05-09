import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../providers/today_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/calendar_strip.dart';
import '../../widgets/task_card.dart';

/// Listd 2027 Today canvas.
///
/// Single-canvas layout (no sidebar / no inspector). The canvas itself
/// is a 20 px-radius rounded card sitting on the ambient backplate
/// (max content width 720 px, centered with 24 px ambient margin on
/// each side). It holds, in order:
///
///   * Newsreader display headline ("Today, Wed Jan 21").
///   * 7-day calendar strip (today − 1 to today + 5).
///   * Today's TaskCard list.
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
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.card ?? scheme.surface;
    final typography = theme.extension<ListdTypography>();

    final todayAsync = ref.watch(todayTasksProvider);
    final headline = _isToday
        ? 'Today, ${DateFormat('EEE MMM d').format(_selected)}'
        : DateFormat('EEEE, MMM d').format(_selected);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720 + 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant, width: 1),
                boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: GestureDetector(
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          _selected = DateTime(now.year, now.month, now.day);
                        });
                      },
                      child: Text(
                        headline,
                        style:
                            typography?.displaySerif ??
                            GoogleFonts.inter(
                              fontSize: 32,
                              height: 40 / 32,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.64,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CalendarStrip(
                      selectedDay: _selected,
                      onDaySelected: (d) => setState(() => _selected = d),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Task> tasks) {
    final expandedId = ref.watch(expandedTaskIdProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    final theme = Theme.of(context);
    final typography = theme.extension<ListdTypography>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? 'A clear day.' : 'Nothing here.',
              style:
                  typography?.displaySerif.copyWith(
                    fontSize: 24,
                    height: 32 / 24,
                  ) ??
                  theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isToday
                  ? 'Capture something with Ctrl + N — or just enjoy it.'
                  : 'Nothing scheduled for this day.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
