import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 2027 · Indigo Edition keyboard-shortcut chip.
///
/// One-glyph chip used wherever the mockups render a `<kbd>` element —
/// capture-row trailing affordance (`[Ctrl] [N]`), empty-state body
/// (`[Ctrl] + [N] to add the next thing.`), and any future shortcut
/// hints.
///
/// Tokens come straight from `mockups/raw/_tokens.css` and the inline
/// styles on `<kbd>` in `mockups/raw/01_today_light.html` /
/// `07_empty_state_light.html`:
///
/// * height 22 px
/// * padding 0/6
/// * radius 6
/// * background `chip` (= `surfaceContainerHighest` in the theme)
/// * 1 px border on `outline`
/// * Inter 11 / 600, color `text-primary`, tabular numerals
class KbdChip extends StatelessWidget {
  const KbdChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // No `alignment` and no explicit `width` — a Container with
    // `alignment` set expands to fill its incoming constraints, which
    // would blow each chip out to the parent Wrap's full maxWidth and
    // stack them vertically. Sizing is driven entirely by the child
    // Text + padding + border. Total height = 16 (Text) + 4 (padding)
    // + 2 (border) = 22 px — matches `<kbd>` in the mockups.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          letterSpacing: 0.02,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Convenience: render a sequence of `KbdChip`s with 4 px gaps between
/// them. Used by the capture row (`[Ctrl] [N]`) and as a building block
/// inside `EmptyState.bodySpans`.
class KbdChipRow extends StatelessWidget {
  const KbdChipRow(this.labels, {super.key, this.gap = 4});

  final List<String> labels;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i != 0) SizedBox(width: gap),
          KbdChip(labels[i]),
        ],
      ],
    );
  }
}
