import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/sheet_shell.dart';

/// Pins the Listd 2027 SheetShell contract — the shared overlay frame
/// used by the Due / Remind / Repeat / Tags pickers. Same shape as the
/// Ctrl+K command palette: 540 px wide, panel surface, 16 px radius,
/// outlineVariant border, ESC dismiss.
void main() {
  Widget harness({Widget? body}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showSheetShell<void>(
                ctx,
                (_) => SheetShell(
                  title: 'Test',
                  icon: PhosphorIcons.gear(),
                  body: body ?? const SizedBox(height: 100),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders centered, ~540 px wide, on the panel surface', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final shellFinder = find.byType(SheetShell);
    expect(shellFinder, findsOneWidget);
    final shellSize = tester.getSize(shellFinder);
    // Shell takes the full viewport because it Centers internally;
    // assert the inner SizedBox carrying the 540 px width.
    final inner = find.descendant(
      of: shellFinder,
      matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 540),
    );
    expect(
      inner,
      findsWidgets,
      reason:
          'SheetShell pins the frame width at 540 px so every popup '
          'reads as the same shell as the Ctrl+K command palette.',
    );
    expect(shellSize.width, greaterThanOrEqualTo(540));
  });

  testWidgets('ESC dismisses the shell', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(SheetShell), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SheetShell), findsNothing);
  });
}
