import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/confirm_destructive_dialog.dart';
import 'package:listd/widgets/sheet_shell.dart';

/// Pins the destructive-confirmation dialog's contract:
///
///  * It wraps a [SheetShell] (so it shares the 540 px / panel /
///    16 px radius / ESC-dismiss frame with every other modal).
///  * Tapping the destructive button returns `true`.
///  * Tapping Cancel returns `false`.
///  * Dismissing without a button (Esc / scrim tap) coalesces to
///    `false` via `showConfirmDestructiveDialog`'s `?? false`.
void main() {
  Widget harness({required ValueChanged<bool> onResult}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await showConfirmDestructiveDialog(
                  ctx,
                  title: 'Delete this task?',
                  body: 'Plan Sunday hike route',
                  confirmLabel: 'Delete',
                );
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders inside a SheetShell with the supplied title + body', (
    tester,
  ) async {
    bool? captured;
    await tester.pumpWidget(harness(onResult: (v) => captured = v));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SheetShell), findsOneWidget);
    expect(find.byType(ConfirmDestructiveDialog), findsOneWidget);
    expect(find.text('Delete this task?'), findsOneWidget);
    expect(find.text('Plan Sunday hike route'), findsOneWidget);
    // Pre-confirmation: callback hasn't fired.
    expect(captured, isNull);
  });

  testWidgets('Delete returns true', (tester) async {
    bool? captured;
    await tester.pumpWidget(harness(onResult: (v) => captured = v));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmDestructiveDialog), findsNothing);
    expect(captured, isTrue);
  });

  testWidgets('Cancel returns false', (tester) async {
    bool? captured;
    await tester.pumpWidget(harness(onResult: (v) => captured = v));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmDestructiveDialog), findsNothing);
    expect(captured, isFalse);
  });
}
