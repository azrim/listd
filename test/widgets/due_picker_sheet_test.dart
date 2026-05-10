import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/due_picker_sheet.dart';
import 'package:listd/widgets/sheet_shell.dart';

/// Pins the Listd 2027 due-date picker shape: SheetShell-based with
/// quick-preset chips (Today / Tomorrow / Next week) above a 7-column
/// month grid. Replaces the stock Material `showDatePicker` so all
/// four metadata pickers share one visual shell.
void main() {
  Future<void> openPicker(WidgetTester tester, {DateTime? initial}) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDueDatePicker(ctx, initial: initial),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders inside a SheetShell with the spec chrome', (
    tester,
  ) async {
    await openPicker(tester);
    expect(find.byType(SheetShell), findsOneWidget);
    expect(find.text('Due date'), findsOneWidget);
  });

  testWidgets('renders the quick-preset chips', (tester) async {
    await openPicker(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Next week'), findsOneWidget);
  });

  testWidgets('renders a 7-column weekday header (M T W T F S S)', (
    tester,
  ) async {
    await openPicker(tester);
    // The weekday header uses single-letter labels so the grid stays
    // 7-wide even on narrow viewports.
    for (final label in const ['M', 'W', 'F', 'S']) {
      expect(
        find.text(label),
        findsWidgets,
        reason: 'weekday header missing label "$label"',
      );
    }
  });
}
