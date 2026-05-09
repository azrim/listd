import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../utils/url_detector.dart';

/// Compact, single-tap-to-open chip rendered for any task step that
/// contains a URL. Lives on the *collapsed* card so the user can reach
/// the link without expanding the task — that's the
/// "see the links directly even when looking at other tasks" goal.
///
/// Visually: 24 px tall pill, oat-soft fill, link glyph, host label.
/// Truncates aggressively so 3 chips comfortably fit on a row at the
/// app's narrowest sane width (~720 px canvas).
class LinkChip extends StatelessWidget {
  const LinkChip({super.key, required this.url, this.maxWidth = 160});

  final String url;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = prettyHost(url);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.link(), size: 12, color: scheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 16 / 11,
                      fontWeight: FontWeight.w500,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final ok = await launchInBrowser(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't open $url")));
    }
  }
}

/// Compact "+N more" indicator placed next to the visible link chips
/// when the collapsed card has more URL steps than fit in the row.
/// Tapping it just toggles expansion via [onTap] — exposes nothing else.
class LinkOverflowChip extends StatelessWidget {
  const LinkOverflowChip({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            '+$count more',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 16 / 11,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
