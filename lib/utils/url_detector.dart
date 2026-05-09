import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Matches `http://...`, `https://...`, and bare `www.example.com` style
/// URLs in arbitrary text. Tuned to avoid greedy-eating trailing punctuation
/// like `.`, `,`, `)` so a URL pasted at the end of a sentence still launches
/// to the right page.
final RegExp _urlPattern = RegExp(
  r'((?:https?://|www\.)[^\s<>"]+[^\s<>".,!?;:)\]}])',
  caseSensitive: false,
);

/// Pulls every URL out of [text]. Returns an empty list when none are found.
List<String> extractUrls(String text) {
  if (text.isEmpty) return const [];
  return _urlPattern
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toList(growable: false);
}

/// `true` when [text] is *just* a URL — used to render a step as a link
/// chip instead of a checkbox + label row.
bool isUrlOnly(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  final match = _urlPattern.firstMatch(trimmed);
  return match != null && match.group(0)!.length == trimmed.length;
}

/// Compact host string used as the visible label on a link chip
/// (e.g. `https://app.fingogin.com/rewards` → `app.fingogin.com`).
String prettyHost(String url) {
  try {
    final uri = Uri.parse(url.startsWith('www.') ? 'https://$url' : url);
    if (uri.host.isEmpty) return url;
    return uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
  } catch (_) {
    return url;
  }
}

/// Opens [url] in the platform's default browser. Bare `www.` strings are
/// promoted to `https://` first. Returns `false` if the launch failed so
/// the caller can show a snackbar.
Future<bool> launchInBrowser(String url) async {
  final fixed = url.startsWith('www.') ? 'https://$url' : url;
  try {
    final uri = Uri.parse(fixed);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('launchInBrowser failed for $url: $e');
    }
    return false;
  }
}
