import 'package:flutter_test/flutter_test.dart';
import 'package:listd/utils/capture_parser.dart';

void main() {
  // Fixed clock: 2027-01-20 09:00 (a Wednesday).
  final clock = DateTime(2027, 1, 20, 9);

  group('CaptureParser tags', () {
    test('extracts a single hashtag', () {
      final r = CaptureParser.parse('Buy milk #errands', now: clock);
      expect(r.title, 'Buy milk');
      expect(r.tags, ['errands']);
    });

    test('extracts multiple hashtags', () {
      final r = CaptureParser.parse('Pay rent #bills #monthly', now: clock);
      expect(r.title, 'Pay rent');
      expect(r.tags, ['bills', 'monthly']);
    });

    test('lowercases hashtags', () {
      final r = CaptureParser.parse('Note #Important', now: clock);
      expect(r.tags, ['important']);
    });

    test('ignores standalone hash', () {
      final r = CaptureParser.parse('Note # alone', now: clock);
      expect(r.tags, isEmpty);
      expect(r.title, contains('#'));
    });
  });

  group('CaptureParser list prefix', () {
    test('extracts @list', () {
      final r = CaptureParser.parse('Send email @work', now: clock);
      expect(r.title, 'Send email');
      expect(r.listHint, 'work');
    });

    test('last @list wins', () {
      final r = CaptureParser.parse('@home Buy milk @errands', now: clock);
      expect(r.title, 'Buy milk');
      expect(r.listHint, 'errands');
    });
  });

  group('CaptureParser star', () {
    test('star marker sets isStarred', () {
      final r = CaptureParser.parse('Important task !', now: clock);
      expect(r.title, 'Important task');
      expect(r.isStarred, isTrue);
    });

    test('no star yields false', () {
      final r = CaptureParser.parse('Plain task', now: clock);
      expect(r.isStarred, isFalse);
    });

    test('exclamation in word is not a star', () {
      final r = CaptureParser.parse('Hello! task', now: clock);
      expect(r.isStarred, isFalse);
      expect(r.title, contains('Hello!'));
    });
  });

  group('CaptureParser dates', () {
    test('today', () {
      final r = CaptureParser.parse('Take walk today', now: clock);
      expect(r.title, 'Take walk');
      expect(r.due, DateTime(2027, 1, 20));
    });

    test('tomorrow', () {
      final r = CaptureParser.parse('Submit form tomorrow', now: clock);
      expect(r.title, 'Submit form');
      expect(r.due, DateTime(2027, 1, 21));
    });

    test('next monday', () {
      final r = CaptureParser.parse('Standup next monday', now: clock);
      expect(r.title, 'Standup');
      // 2027-01-20 is Wednesday; next Monday is 2027-01-25.
      expect(r.due, DateTime(2027, 1, 25));
    });

    test('weekday alone', () {
      final r = CaptureParser.parse('Lunch friday', now: clock);
      expect(r.title, 'Lunch');
      // Friday after Wed 1/20 is 1/22.
      expect(r.due, DateTime(2027, 1, 22));
    });

    test('time only — at 3 (PM heuristic)', () {
      final r = CaptureParser.parse('Coffee at 3', now: clock);
      expect(r.title, 'Coffee');
      // 09:00 → 15:00 today (3 < 8 → PM).
      expect(r.due, DateTime(2027, 1, 20, 15));
    });

    test('time with am explicit', () {
      final r = CaptureParser.parse('Run at 6am', now: clock);
      expect(r.due, DateTime(2027, 1, 20, 6));
    });

    test('time with pm explicit', () {
      final r = CaptureParser.parse('Dinner at 7pm', now: clock);
      expect(r.due, DateTime(2027, 1, 20, 19));
    });

    test('24-hour time', () {
      final r = CaptureParser.parse('Sync at 14:30', now: clock);
      expect(r.due, DateTime(2027, 1, 20, 14, 30));
    });

    test('tomorrow at 3', () {
      final r = CaptureParser.parse('Call client tomorrow at 3', now: clock);
      expect(r.title, 'Call client');
      expect(r.due, DateTime(2027, 1, 21, 15));
    });

    test('time in past today rolls to tomorrow', () {
      final lateClock = DateTime(2027, 1, 20, 17);
      final r = CaptureParser.parse('Call at 3', now: lateClock);
      // 15:00 today is past 17:00, so it's tomorrow at 15:00.
      expect(r.due, DateTime(2027, 1, 21, 15));
    });
  });

  group('CaptureParser combined', () {
    test('star + tag + date + list', () {
      final r = CaptureParser.parse(
        'Review the spec tomorrow at 3 #errands @work !',
        now: clock,
      );
      expect(r.title, 'Review the spec');
      expect(r.due, DateTime(2027, 1, 21, 15));
      expect(r.tags, ['errands']);
      expect(r.listHint, 'work');
      expect(r.isStarred, isTrue);
    });

    test('only title', () {
      final r = CaptureParser.parse('Walk the dog', now: clock);
      expect(r.title, 'Walk the dog');
      expect(r.due, isNull);
      expect(r.isStarred, isFalse);
      expect(r.tags, isEmpty);
      expect(r.listHint, isNull);
    });

    test('empty input', () {
      final r = CaptureParser.parse('', now: clock);
      expect(r.title, isEmpty);
      expect(r.due, isNull);
    });

    test('only whitespace', () {
      final r = CaptureParser.parse('   ', now: clock);
      expect(r.title, isEmpty);
    });
  });
}
