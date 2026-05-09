import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Listd 2027 · Indigo Edition horizontal date track.
///
/// Replaces the old 7-day "calendar grid" cards with a quieter strip
/// per `docs/redesign/2027-indigo/03_components.md` §4.
///
/// Anatomy:
///
/// ```
/// ··· · · · ●═════● · · · ···
///     Fri Sat Sun Mon Tue Wed Thu     (today is the indigo capsule)
/// ```
///
///  * Track height: **56 px**
///  * Each day: 32 px wide, 56 px tall, vertically anchored to a
///    1 px slate-200 centerline that runs through the track.
///  * **Today** sits *on* the line as a 32 × 32 indigo-600 capsule
///    (white text). Other days sit *above* the line, slate text only.
///  * Past days: slate-400. Future days: slate-700 (`onSurface`).
///  * Tap any day → scopes the parent screen to that day.
///  * Density bars are gone — the indigo system carries scope through
///    type and capsule fill, not segmented bars.
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
    final centerlineColor = scheme.outlineVariant;

    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The 1 px centerline sits at the vertical midpoint and runs
          // edge-to-edge behind the day cells.
          Positioned(
            left: 0,
            right: 0,
            top: 28,
            child: Container(height: 1, color: centerlineColor),
          ),
          ListView.builder(
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
              final isPast = day.isBefore(today);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DayCell(
                  day: day,
                  isToday: isToday,
                  isSelected: isSelected,
                  isPast: isPast,
                  onTap: () => onDaySelected(day),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
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
    final isDark = scheme.brightness == Brightness.dark;

    // Today renders as a 32 × 32 indigo-600 capsule that sits on the
    // centerline. Selected (non-today) days render as a slate-200
    // chip behind the day-of-month so the eye can find them.
    final capsuleFill = isToday
        ? scheme.primary
        : isSelected
        ? scheme.outlineVariant
        : Colors.transparent;
    final capsuleFg = isToday
        ? scheme.onPrimary
        : isSelected
        ? scheme.onSurface
        : isPast
        ? (isDark ? AppColors.slate500 : AppColors.slate400)
        : scheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Day-of-week label sits above the centerline. Compact —
              // no bold, no caps lock, just a quiet two-letter glyph.
              SizedBox(
                height: 20,
                child: Center(
                  child: Text(
                    _dowLabel(day.weekday),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w500,
                      color: isToday || isSelected
                          ? capsuleFg
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              // Day-of-month sits in a 32 × 32 capsule at the bottom,
              // centered on the track centerline (the centerline is at
              // y=28; the capsule is 24–56, so its midpoint lands on
              // y=40 — the cell vertically anchors the day glyph there
              // visually because it has only 24 px of bottom space).
              Container(
                width: 32,
                height: 32,
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
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                    color: capsuleFg,
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
    // Mon = 1 … Sun = 7. Two letters keeps the cell narrow and the
    // text readable even at compact font scales.
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return labels[weekday - 1];
  }
}
