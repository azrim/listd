import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Listd 2027 · Indigo Edition empty-state component.
///
/// One component, used everywhere an absence of content needs a voice
/// (Today / Inbox / a list / search results / …). The composition is:
///
/// ```
///       [icon · 32 px Phosphor regular, slate-300]
///
///       Headline (Newsreader serif, 22 / 28, slate-700)
///       Body (Inter 14 / 20, slate-500, italic)
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
    this.actionLabel,
    this.onAction,
    this.maxWidth = 360,
  });

  final IconData icon;
  final String headline;
  final String? body;
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
            Icon(icon, size: 32, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.22,
                color: scheme.onSurface,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
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
