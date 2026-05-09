import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Listd 2027 · Indigo Edition horizontal date track.
///
/// Per `docs/redesign/2027-indigo/mockups/01_today_light.png`: a
/// flat 7-cell strip stretched edge-to-edge, with DAY-of-week caps
/// stacked over the DATE number. Today is a solid indigo capsule
/// wrapping the date glyph; selected (non-today) is indigo-soft.
/// Cells are separated by sub-pixel hairlines.
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
    // Center today in a 7-day window: today − 3 … today + 3.
    final start = today.subtract(const Duration(days: 3));
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = start.add(Duration(days: i));
                  final isToday = _sameDay(day, today);
                  final isSelected = _sameDay(day, selectedDay);
                  final isPast = day.isBefore(today);
                  return _DayCell(
                    day: day,
                    isToday: isToday,
                    isSelected: isSelected,
                    isPast: isPast,
                    onTap: () => onDaySelected(day),
                  );
                },
              ),
            ),
            if (i < 6)
              Container(
                width: 1,
                height: 32,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
          ],
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Today's date glyph sits inside a solid indigo capsule.
    // Selected (non-today) day uses an indigo-soft chip behind the
    // date so the eye lands there. Other days are plain text.
    final Color dateFg = isToday
        ? scheme.onPrimary
        : isSelected
        ? scheme.primary
        : isPast
        ? scheme.onSurfaceVariant
        : scheme.onSurface;
    final Color capsuleFill = isToday
        ? scheme.primary
        : isSelected
        ? scheme.primaryContainer
        : Colors.transparent;
    final Color dowFg = isToday
        ? scheme.primary
        : isSelected
        ? scheme.primary
        : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _dowLabel(day.weekday),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08,
                  color: dowFg,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: capsuleFill,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: dateFg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
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
