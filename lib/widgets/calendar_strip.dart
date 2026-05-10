import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Listd 2027 · Indigo Edition horizontal date track.
///
/// Per confirmed mockup `mockups/raw/01_today_light.html` + `_tokens.css`:
///
///  * 7 fixed-width 56 × 56 px cells, each showing stacked DOW label
///    + day number.
///  * A horizontal hairline runs across the full track width at the
///    vertical midpoint (y ≈ 28 px from the cell top).
///  * Today's cell is a full-size 56 × 56 accent-filled pill
///    (`borderRadius: 999`) wrapping **both** the DOW label and the
///    day number in `onPrimary` color, offset −4 px upward.
///  * Past days render at 50 % opacity.
///  * No vertical separators between cells.
class CalendarStrip extends ConsumerWidget {
  const CalendarStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 3));
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            // Horizontal through-line at the vertical midpoint of the
            // 56 px cells (y = 28 px from cell top). The cell top sits
            // at y = 0 inside this SizedBox (today's −4 px offset
            // overflows upward via Transform).
            Positioned(
              left: 0,
              right: 0,
              top: 28,
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
            // Date cells.
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  _DayCell(
                    day: start.add(Duration(days: i)),
                    isToday: _sameDay(start.add(Duration(days: i)), today),
                    isSelected: _sameDay(
                      start.add(Duration(days: i)),
                      selectedDay,
                    ),
                    isPast: start.add(Duration(days: i)).isBefore(today),
                    onTap: () => onDaySelected(start.add(Duration(days: i))),
                  ),
              ],
            ),
          ],
        ),
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

    // DOW label color.
    final Color dowFg = isToday ? scheme.onPrimary : scheme.onSurfaceVariant;

    // Day number color.
    final Color numFg = isToday
        ? scheme.onPrimary
        : isSelected
        ? scheme.primary
        : scheme.onSurface;

    // Cell background — only today gets the accent fill.
    final Color cellBg = isToday ? scheme.primary : Colors.transparent;

    Widget cell = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(999),
        ),
        // Today's cell shifts up 4 px per mockup `margin-top: -4px`.
        transform: isToday ? Matrix4.translationValues(0, -4, 0) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dowLabel(day.weekday),
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 16 / 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: dowFg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.32,
                color: numFg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );

    // Past days at 50 % opacity per mockup `.date-cell.is-past`.
    if (isPast) {
      cell = Opacity(opacity: 0.5, child: cell);
    }

    return cell;
  }

  static String _dowLabel(int weekday) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[weekday - 1];
  }
}
