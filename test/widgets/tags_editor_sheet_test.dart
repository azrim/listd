import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/models/task.dart';
import 'package:listd/providers/tasks_provider.dart';
import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/sheet_shell.dart';
import 'package:listd/widgets/tags_editor_sheet.dart';

/// Pins the Listd 2027 tags editor shape: SheetShell with a search /
/// add `TextField` in the body, an "Applied" section showing the
/// task's existing tags (with a remove icon), and a "Suggested"
/// section sourced from `allTasksProvider`. Replaces the previous
/// `showModalBottomSheet` centered-card layout.
void main() {
  Future<void> openEditor(
    WidgetTester tester, {
    List<String> initial = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Tags editor reads `allTasksProvider` for the suggestions
          // section; stub it out so the test doesn't try to spin up
          // Supabase / Drift.
          allTasksProvider.overrideWith(
            (ref) => const AsyncValue<List<Task>>.data(<Task>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showTagsEditor(ctx, initial: initial),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders inside a SheetShell with "Tags" header', (tester) async {
    await openEditor(tester);
    expect(find.byType(SheetShell), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
  });

  testWidgets('embeds a search/add TextField', (tester) async {
    await openEditor(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search or add a tag…'), findsOneWidget);
  });

  testWidgets('shows applied tags when initial is non-empty', (tester) async {
    await openEditor(tester, initial: const ['focus', 'urgent']);
    // _SectionLabel uppercases the caption ('APPLIED (2)') per the
    // 11 px / 600 weight / 0.06 em caption ramp.
    expect(find.textContaining('APPLIED'), findsOneWidget);
    expect(find.text('focus'), findsOneWidget);
    expect(find.text('urgent'), findsOneWidget);
  });
}
