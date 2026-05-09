import 'package:flutter_test/flutter_test.dart';
import 'package:listd/utils/url_detector.dart';

void main() {
  group('extractUrls', () {
    test('returns empty list for empty input', () {
      expect(extractUrls(''), isEmpty);
    });

    test('matches a single https URL', () {
      expect(extractUrls('check https://example.com out'), [
        'https://example.com',
      ]);
    });

    test('matches a bare www URL', () {
      expect(extractUrls('see www.fingogin.com'), ['www.fingogin.com']);
    });

    test('matches multiple URLs in one string', () {
      final urls = extractUrls('one https://a.com two http://b.org/x?y=1 done');
      expect(urls, ['https://a.com', 'http://b.org/x?y=1']);
    });

    test('strips trailing punctuation that is not part of the URL', () {
      expect(extractUrls('See https://example.com.'), ['https://example.com']);
      expect(extractUrls('open https://example.com,'), ['https://example.com']);
      expect(extractUrls('(https://example.com)'), ['https://example.com']);
    });
  });

  group('isUrlOnly', () {
    test('false for empty', () => expect(isUrlOnly(''), false));

    test('true for a bare URL', () {
      expect(isUrlOnly('https://example.com'), true);
      expect(isUrlOnly('  https://example.com  '), true);
    });

    test('false when text surrounds the URL', () {
      expect(isUrlOnly('open https://example.com'), false);
      expect(isUrlOnly('https://example.com here'), false);
    });
  });

  group('prettyHost', () {
    test('strips scheme and www', () {
      expect(prettyHost('https://www.fingogin.com/x'), 'fingogin.com');
      expect(prettyHost('http://api.example.com/y'), 'api.example.com');
    });

    test('promotes bare www to https', () {
      expect(prettyHost('www.example.com'), 'example.com');
    });

    test('falls back to input on parse error', () {
      expect(prettyHost('not a url at all'), 'not a url at all');
    });
  });
}
