import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/models/task.dart';
import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/confirm_destructive_dialog.dart';
import 'package:listd/widgets/task_card.dart';

/// Pins the destructive-confirmation gate on task delete.
///
///  * Tapping the action rail's "Delete task" row opens
///    [ConfirmDestructiveDialog] (does NOT delete immediately).
///  * Tapping Cancel closes the dialog WITHOUT firing the delete or
///    the post-delete toast.
///
/// The test deliberately doesn't drive the confirm path — the
/// underlying delete writes through a Drift DAO which would need a
/// full database harness to fake. The dialog test
/// (`confirm_destructive_dialog_test.dart`) already pins the
/// confirm-vs-cancel return values, so this test only needs to pin
/// that the gate is wired correctly.
void main() {
  Future<void> pumpHarness(WidgetTester tester) async {
    // Expand the surface so the expanded TaskCard's metadata Row
    // (action rail + chips) doesn't overflow — the same Row that the
    // existing `task_card_test.dart` whitelists at 800 px. We need a
    // clean tree so `tester.takeException()` returning null below
    // signals an actual problem with the delete flow, not the
    // unrelated layout warning.
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final task = Task(
      id: 't1',
      taskListId: 'l1',
      title: 'Plan Sunday hike',
      updated: DateTime(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ListView(
              children: [
                TaskCard(
                  task: task,
                  listId: 'l1',
                  isExpanded: true,
                  onToggleExpand: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Let the expand animation settle so the action rail is visible.
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Delete tap opens the confirmation dialog', (tester) async {
    await pumpHarness(tester);

    // Action rail's destructive row.
    final deleteRow = find.text('Delete task');
    expect(deleteRow, findsOneWidget);

    await tester.tap(deleteRow, warnIfMissed: false);
    await tester.pumpAndSettle();

    // The confirmation dialog should now be on screen, NOT the
    // mutation, NOT a snackbar.
    expect(find.byType(ConfirmDestructiveDialog), findsOneWidget);
    // Scope text expectations to the dialog so they don't collide with
    // the task title rendered in the inline-edit field underneath.
    expect(
      find.descendant(
        of: find.byType(ConfirmDestructiveDialog),
        matching: find.text('Delete this task?'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ConfirmDestructiveDialog),
        matching: find.text('Plan Sunday hike'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cancel closes the dialog without deleting', (tester) async {
    await pumpHarness(tester);

    await tester.tap(find.text('Delete task'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmDestructiveDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog dismissed; the task card is still in the tree because
    // the cancel path returns early before deleteTask.
    expect(find.byType(ConfirmDestructiveDialog), findsNothing);
    expect(find.byType(TaskCard), findsOneWidget);
  });
}
