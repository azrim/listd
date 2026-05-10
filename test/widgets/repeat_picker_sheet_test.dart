import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/repeat_picker_sheet.dart';
import 'package:listd/widgets/sheet_shell.dart';

/// Pins the Listd 2027 repeat picker shape: list-of-rows with one row
/// per `RepeatType`, plus an inline-expansion tail (interval stepper /
/// weekday chips) on the selected row. Replaces the previous
/// `showModalBottomSheet` chip rail + stepper stack.
void main() {
  Future<void> openPicker(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRepeatPicker(ctx),
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

  testWidgets('renders inside a SheetShell with "Repeat" header', (
    tester,
  ) async {
    await openPicker(tester);
    expect(find.byType(SheetShell), findsOneWidget);
    expect(find.text('Repeat'), findsOneWidget);
  });

  testWidgets('renders one row per RepeatType', (tester) async {
    await openPicker(tester);
    for (final label in const [
      'Daily',
      'Weekly',
      'Monthly',
      'Yearly',
      'Custom',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing row "$label"');
    }
  });

  testWidgets("provides a destructive \"Don't repeat\" footer", (tester) async {
    await openPicker(tester);
    expect(find.text("Don't repeat"), findsOneWidget);
  });
}
