import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'kbd_chip.dart';

/// Listd 2027 · Indigo Edition empty-state component.
///
/// One component, used everywhere an absence of content needs a voice
/// (Today / Inbox / a list / search results / …). The composition is:
///
/// ```
///       [icon · 22 px Phosphor regular on a 48 px slate disc]
///
///       Headline (Newsreader serif, 24 / 32, slate-900)
///       Body (Inter 13 / 18, slate-500, italic)
///         — or —
///       Body with inline KbdChip spans
///         (e.g. `Ctrl` + `N` to add the next thing.)
///
///       [Optional CTA — small text button, indigo-600]
/// ```
///
/// All copy + icon + CTA come from the call site as props — there is
/// nothing surface-specific in the widget itself.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.headline,
    this.body,
    this.bodySpans,
    this.actionLabel,
    this.onAction,
    this.maxWidth = 360,
  }) : assert(
         body == null || bodySpans == null,
         'Pass either `body` or `bodySpans`, not both.',
       );

  final IconData icon;
  final String headline;

  /// Plain italic body line — mockups use this for free-form copy
  /// like "Capture your first task with the input above.".
  final String? body;

  /// Mixed body line with inline kbd chips. Each entry is either a
  /// `String` (renders as the same italic body text) or a `KbdChip`
  /// (renders inline with 4 px breathing room on each side).
  ///
  /// Mirrors the mockup's `<kbd>Ctrl</kbd> + <kbd>N</kbd> to add the
  /// next thing.` rendering.
  final List<Object>? bodySpans;

  final String? actionLabel;
  final VoidCallback? onAction;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Slate-soft filled disc behind the icon — per
            // `07_empty_state_light.png` and `10_components_overview.png`
            // empty states read as a "small absence" anchored by a
            // muted disc, not a hairline ring.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                fontSize: 24,
                height: 32 / 24,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.48,
                color: scheme.onSurface,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (bodySpans != null) ...[
              const SizedBox(height: 8),
              _BodySpans(spans: bodySpans!),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAction,
                icon: Icon(PhosphorIcons.plus(), size: 14),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Render a `bodySpans` list as a centered, wrapping line of italic
/// text + `KbdChip` widgets.
class _BodySpans extends StatelessWidget {
  const _BodySpans({required this.spans});

  final List<Object> spans;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = GoogleFonts.inter(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: scheme.onSurfaceVariant,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final span in spans)
          if (span is KbdChip)
            span
          else if (span is String)
            Text(span, style: textStyle, textAlign: TextAlign.center)
          else
            // Fallback for unexpected types — shouldn't happen at
            // call sites we own, but stay defensive.
            const SizedBox.shrink(),
      ],
    );
  }
}
