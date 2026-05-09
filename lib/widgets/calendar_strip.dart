import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/today_provider.dart';
import '../theme/app_theme.dart';

/// 7-day calendar strip used by the Today canvas.
///
/// The strip starts from "today − 1" and runs through "today + 5"
/// (yesterday is visible for catch-up; the next 5 days for forward
/// planning). Each day card shows the day-of-week label, the day
/// number, and a 4 px density bar at the bottom rendered from up to
/// 8 segments (`min(taskCount, 8)`).
///
/// Selecting a day calls [onDaySelected]; the parent screen is
/// responsible for filtering its task list to that day.
class CalendarStrip extends ConsumerWidget {
  const CalendarStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  /// The day currently highlighted in the strip. Compared by year /
  /// month / day; time component is ignored.
  final DateTime selectedDay;

  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 1));
    final countsAsync = ref.watch(tasksByDayProvider(start));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = start.add(Duration(days: index));
          final isToday =
              day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isSelected =
              day.year == selectedDay.year &&
              day.month == selectedDay.month &&
              day.day == selectedDay.day;
          final count = countsAsync.valueOrNull?[day] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DayCard(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              count: count,
              onTap: () => onDaySelected(day),
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = Theme.of(context).extension<ListdSurfaces>();
    final cardBg = surfaces?.card ?? scheme.surface;

    Color fill = cardBg;
    Color borderColor = scheme.outlineVariant;
    if (isSelected) {
      fill = scheme.primaryContainer;
      borderColor = scheme.primary.withValues(alpha: 0.5);
    } else if (isToday) {
      borderColor = scheme.primary.withValues(alpha: 0.4);
    }

    final dowLabel = _dowLabel(day.weekday);
    final segments = count.clamp(0, 8);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dowLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 16 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  height: 22 / 18,
                  fontWeight: FontWeight.w600,
                  color: isToday || isSelected
                      ? scheme.primary
                      : scheme.onSurface,
                ),
              ),
              const Spacer(),
              _DensityBar(segments: segments, scheme: scheme),
            ],
          ),
        ),
      ),
    );
  }

  static String _dowLabel(int weekday) {
    // Mon = 1 … Sun = 7.
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[weekday - 1];
  }
}

class _DensityBar extends StatelessWidget {
  const _DensityBar({required this.segments, required this.scheme});

  final int segments;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (segments == 0) {
      return const SizedBox(height: 4);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(8, (i) {
        final on = i < segments;
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: on
                ? scheme.primary.withValues(alpha: 0.7)
                : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
