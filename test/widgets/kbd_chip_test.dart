import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/widgets/empty_state.dart';
import 'package:listd/widgets/kbd_chip.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  testWidgets(
    'KbdChip sizes to its label, does not expand to fill bounded constraints',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, // simulate the EmptyState ConstrainedBox.
              child: Wrap(
                alignment: WrapAlignment.center,
                children: const [KbdChip('Ctrl'), KbdChip('N')],
              ),
            ),
          ),
        ),
      );

      final ctrlSize = tester.getSize(
        find.ancestor(of: find.text('Ctrl'), matching: find.byType(Container)),
      );
      final nSize = tester.getSize(
        find.ancestor(of: find.text('N'), matching: find.byType(Container)),
      );

      // The whole point of the fix: each chip must be narrower than the
      // 360 px line so they sit inline next to each other instead of
      // each filling the line and stacking. 80 px is a comfortable cap
      // that any reasonable rendering of "Ctrl" / "N" will respect.
      expect(ctrlSize.width, lessThan(80));
      expect(nSize.width, lessThan(40));

      // Height must be exactly the spec (text 16 + padding 4 + border 2).
      expect(ctrlSize.height, 22);
      expect(nSize.height, 22);
    },
  );

  testWidgets(
    'EmptyState bodySpans flow inline (no chip stacking)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: PhosphorIcons.tray(),
              headline: 'Inbox is clear.',
              bodySpans: const [
                KbdChip('Ctrl'),
                '+',
                KbdChip('N'),
                'to add the next thing.',
              ],
            ),
          ),
        ),
      );

      // Both chips and the trailing text must render.
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(find.text('to add the next thing.'), findsOneWidget);

      // The Wrap must position both chips on the same horizontal line
      // (top y must be equal) — the previous render stacked them.
      final ctrlChipBox = tester.getRect(
        find.ancestor(of: find.text('Ctrl'), matching: find.byType(Container)),
      );
      final nChipBox = tester.getRect(
        find.ancestor(of: find.text('N'), matching: find.byType(Container)),
      );
      expect(ctrlChipBox.top, nChipBox.top);
    },
  );
}
