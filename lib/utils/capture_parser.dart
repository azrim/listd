/// Listd 2027 P6 — pure-Dart parser for the capture sheet input.
///
/// The capture sheet lets users type free-form text and have it
/// parsed into a structured `Task` partial:
///
/// ```
///   "Review the spec tomorrow at 3 #errands @work !"
///        ^title^^^^^^^   ^due^^^^^^ ^tag^^^ ^list^ ^star
/// ```
///
/// The parser is intentionally:
///
///  * **Pure**: no I/O, no clock — pass `now` for deterministic tests.
///  * **Lenient**: any unrecognised token stays in the title.
///  * **Order-agnostic**: markers can appear anywhere.
///
/// Recognised markers:
///
///  * `#tag` — adds a hashtag (no leading whitespace required).
///  * `@list` — sets the target list hint (last one wins).
///  * `!`     — toggles the starred flag (any standalone `!`).
///  * Date/time phrases at the END of the input only
///    (so a `!` mid-sentence doesn't gobble random words).
///
/// Recognised dates (case-insensitive):
///
///  * `today`, `tonight` — `now` rounded down to start of day.
///  * `tomorrow`         — start of day + 1.
///  * `next <weekday>`   — next Mon-Sun (1-7).
///  * `<weekday>`        — next occurrence of that weekday.
///  * `at <hour>[am|pm]` — appended to a parsed date or applied to
///    today if no date precedes it.
library;

class CaptureResult {
  const CaptureResult({
    required this.title,
    this.due,
    this.isStarred = false,
    this.listHint,
    this.tags = const [],
  });

  final String title;
  final DateTime? due;
  final bool isStarred;
  final String? listHint;
  final List<String> tags;

  CaptureResult copyWith({
    String? title,
    DateTime? due,
    bool? isStarred,
    String? listHint,
    List<String>? tags,
  }) {
    return CaptureResult(
      title: title ?? this.title,
      due: due ?? this.due,
      isStarred: isStarred ?? this.isStarred,
      listHint: listHint ?? this.listHint,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CaptureResult &&
        other.title == title &&
        other.due == due &&
        other.isStarred == isStarred &&
        other.listHint == listHint &&
        _listEq(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(title, due, isStarred, listHint, tags);

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class CaptureParser {
  CaptureParser._();

  static const Map<String, int> _weekdays = {
    'monday': DateTime.monday,
    'mon': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'wed': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'thu': DateTime.thursday,
    'thurs': DateTime.thursday,
    'friday': DateTime.friday,
    'fri': DateTime.friday,
    'saturday': DateTime.saturday,
    'sat': DateTime.saturday,
    'sunday': DateTime.sunday,
    'sun': DateTime.sunday,
  };

  static CaptureResult parse(String input, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final tokens = input.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty || (tokens.length == 1 && tokens.first.isEmpty)) {
      return const CaptureResult(title: '');
    }

    final tags = <String>[];
    String? listHint;
    var isStarred = false;
    final remaining = <String>[];

    for (final raw in tokens) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('#') && t.length > 1) {
        tags.add(t.substring(1).toLowerCase());
      } else if (t.startsWith('@') && t.length > 1) {
        listHint = t.substring(1).toLowerCase();
      } else if (t == '!') {
        isStarred = true;
      } else {
        remaining.add(t);
      }
    }

    final (due, titleTokens) = _extractDate(remaining, clock);
    final title = titleTokens.join(' ').trim();

    return CaptureResult(
      title: title,
      due: due,
      isStarred: isStarred,
      listHint: listHint,
      tags: tags,
    );
  }

  static (DateTime?, List<String>) _extractDate(
    List<String> tokens,
    DateTime now,
  ) {
    if (tokens.isEmpty) return (null, tokens);

    final today = DateTime(now.year, now.month, now.day);
    final lower = tokens.map((t) => t.toLowerCase()).toList();

    DateTime? base;
    int matchStart = tokens.length;
    int? hour;
    int? minute;
    bool timeWasBare = false;

    // 1. "at <hour>[am|pm]" — find from the right.
    for (var i = lower.length - 2; i >= 0; i--) {
      if (lower[i] == 'at') {
        final timeMatch = _parseTime(lower[i + 1]);
        if (timeMatch != null) {
          hour = timeMatch.$1;
          minute = timeMatch.$2;
          timeWasBare = timeMatch.$3;
          matchStart = i;
          break;
        }
      }
    }

    // 2. Date phrases at the end of the remaining tokens.
    //    Try longest first ("next monday") before single-word matches.
    if (matchStart >= 2) {
      final prev = lower[matchStart - 2];
      final last = lower[matchStart - 1];
      if (prev == 'next' && _weekdays.containsKey(last)) {
        base = _nextWeekday(today, _weekdays[last]!, alwaysFuture: true);
        matchStart -= 2;
      }
    }
    if (base == null && matchStart > 0) {
      final last = lower[matchStart - 1];
      if (last == 'today' || last == 'tonight') {
        base = today;
        matchStart -= 1;
      } else if (last == 'tomorrow') {
        base = today.add(const Duration(days: 1));
        matchStart -= 1;
      } else if (_weekdays.containsKey(last)) {
        base = _nextWeekday(today, _weekdays[last]!);
        matchStart -= 1;
      }
    }

    // 3. If we got a time but no date, default to today. Bare times
    // (no am/pm and no colon) are ambiguous — roll forward to
    // tomorrow if the resolved time has already passed. Explicit
    // am/pm/24h times stay on today even if past.
    if (hour != null && base == null) {
      final candidate = DateTime(
        today.year,
        today.month,
        today.day,
        hour,
        minute ?? 0,
      );
      if (timeWasBare && candidate.isBefore(now)) {
        base = today.add(const Duration(days: 1));
      } else {
        base = today;
      }
    }

    if (base == null) {
      return (null, tokens);
    }

    final due = (hour != null)
        ? DateTime(base.year, base.month, base.day, hour, minute ?? 0)
        : base;

    return (due, tokens.sublist(0, matchStart));
  }

  /// Parse "3", "3am", "3pm", "15:30".
  /// Returns `(hour, minute, isBare)` where `isBare` flags ambiguous
  /// times (no am/pm, no colon) so the caller can apply a heuristic.
  static (int, int, bool)? _parseTime(String t) {
    final colon = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t);
    if (colon != null) {
      final h = int.parse(colon.group(1)!);
      final m = int.parse(colon.group(2)!);
      if (h <= 23 && m <= 59) return (h, m, false);
      return null;
    }
    final ampm = RegExp(r'^(\d{1,2})(am|pm)$').firstMatch(t);
    if (ampm != null) {
      var h = int.parse(ampm.group(1)!);
      final pm = ampm.group(2) == 'pm';
      if (pm && h < 12) h += 12;
      if (!pm && h == 12) h = 0;
      if (h <= 23) return (h, 0, false);
      return null;
    }
    final bare = RegExp(r'^(\d{1,2})$').firstMatch(t);
    if (bare != null) {
      final h = int.parse(bare.group(1)!);
      // "at 3" — assume PM if hour < 8 (afternoon appointments are
      // the common case), AM otherwise. Marked bare so the caller
      // can roll forward when the time has already passed.
      if (h <= 23) return (h < 8 ? h + 12 : h, 0, true);
    }
    return null;
  }

  static DateTime _nextWeekday(
    DateTime today,
    int targetWeekday, {
    bool alwaysFuture = false,
  }) {
    var diff = (targetWeekday - today.weekday) % 7;
    if (diff == 0 && alwaysFuture) diff = 7;
    return today.add(Duration(days: diff));
  }
}
