import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/models/task.dart';
import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/task_card.dart';
// AppTheme.lightTheme / .darkTheme are defined on AppTheme.

/// Regression: shipping the morph as `BoxDecoration(borderRadius: ...,
/// border: Border(non-uniform sides))` caused Flutter to assert
/// `A borderRadius can only be given on borders with uniform colors`
/// every paint pass once a card was tapped to expand. The test pumps a
/// few frames mid-animation to make sure no such exception is thrown.
void main() {
  testWidgets('TaskCard expands and collapses without rendering exceptions', (
    tester,
  ) async {
    final task = Task(
      id: 't1',
      taskListId: 'l1',
      title: 'tasky',
      updated: DateTime(2026),
    );

    // Specifically asserts on the borderRadius / non-uniform-colors
    // crash; ignores unrelated layout errors (the action rail
    // overflows the test's default 800-px viewport, which is fine).
    void expectNoBorderCrash(int frame) {
      final exc = tester.takeException();
      if (exc == null) return;
      if (exc is FlutterError &&
          exc.toString().contains('RenderFlex overflowed')) {
        return;
      }
      fail('TaskCard threw a paint exception on frame $frame:\n$exc');
    }

    Future<void> pumpHarness({required bool isExpanded}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 720)),
              child: Scaffold(
                body: ListView(
                  children: [
                    TaskCard(
                      task: task,
                      listId: 'l1',
                      isExpanded: isExpanded,
                      onToggleExpand: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pumpHarness(isExpanded: false);
    expectNoBorderCrash(-1);

    await pumpHarness(isExpanded: true);
    // Pump a handful of frames during the expand animation so the
    // intermediate Border.lerp values are exercised by the renderer.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expectNoBorderCrash(i);
    }

    await pumpHarness(isExpanded: false);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expectNoBorderCrash(i);
    }
  });
}
