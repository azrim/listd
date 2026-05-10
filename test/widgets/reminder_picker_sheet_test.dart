import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/reminder_picker_sheet.dart';
import 'package:listd/widgets/sheet_shell.dart';

/// Pins the Listd 2027 reminder picker shape: time-only presets on a
/// SheetShell. The previous flow chained `showDatePicker` then
/// `showTimePicker`; the redesign drops the date step entirely
/// because reminders are almost always "later today / tomorrow
/// morning". Date is implied (today, or the task's due date if set).
void main() {
  Future<void> openPicker(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showReminderPicker(ctx),
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

  testWidgets('renders inside a SheetShell with "Remind me" header', (
    tester,
  ) async {
    await openPicker(tester);
    expect(find.byType(SheetShell), findsOneWidget);
    expect(find.text('Remind me'), findsOneWidget);
  });

  testWidgets('renders the canonical time-only preset rows', (tester) async {
    await openPicker(tester);
    expect(find.text('In 30 minutes'), findsOneWidget);
    expect(find.text('In 1 hour'), findsOneWidget);
    expect(find.text('In 2 hours'), findsOneWidget);
    expect(find.text('Tonight'), findsOneWidget);
    expect(find.text('Tomorrow morning'), findsOneWidget);
    expect(find.text('Custom…'), findsOneWidget);
  });

  testWidgets('does not embed a CalendarDatePicker (reminder is time-only)', (
    tester,
  ) async {
    await openPicker(tester);
    expect(
      find.byType(CalendarDatePicker),
      findsNothing,
      reason:
          'Reminder picker is time-only by design; date is implied. '
          'A calendar widget would mean we regressed back to the '
          'date-then-time chain we deliberately removed.',
    );
  });
}
