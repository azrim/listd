import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listd/providers/sync_provider.dart';
import 'package:listd/providers/task_lists_provider.dart'
    show taskSyncServiceProvider;
import 'package:listd/services/sync/task_sync_service.dart';
import 'package:listd/theme/app_colors.dart';
import 'package:listd/theme/app_theme.dart';
import 'package:listd/widgets/sync_status_pill.dart';

/// Pins the sync pill's surface stack invariant: the pill renders on
/// `surfaces.card` (= one slate stop above the panel it sits on), so
/// it has visible separation in both light + dark mode after the
/// 02_today_dark mock fidelity pass that flattened panel == canvas in
/// dark mode.
void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme) async {
    final fakeService = _FakeTaskSyncService();
    addTearDown(fakeService._dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Fake the service so SyncStateNotifier can subscribe to its
          // ValueNotifiers without spinning up Drift / Supabase.
          taskSyncServiceProvider.overrideWithValue(fakeService),
          // Empty count stream — `syncStateProvider` listens to this
          // with `fireImmediately: true`; an empty stream means no
          // updates land but the listener doesn't crash.
          pendingSyncCountsProvider.overrideWith(
            (ref) => const Stream<({int lists, int tasks})>.empty(),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(body: Center(child: SyncStatusPill())),
        ),
      ),
    );
    await tester.pump();
  }

  Material findPillMaterial(WidgetTester tester) {
    // The first Material in the SyncStatusPill subtree is the pill
    // background (the InkWell adds a second Material below it).
    final finder = find.descendant(
      of: find.byType(SyncStatusPill),
      matching: find.byType(Material),
    );
    expect(finder, findsAtLeastNWidgets(1));
    return tester.widget<Material>(finder.first);
  }

  testWidgets('pill renders on surfaces.card in dark mode', (tester) async {
    await pump(tester, AppTheme.darkTheme);
    final pill = findPillMaterial(tester);
    // surfaces.card in dark = slate-700, one stop brighter than the
    // flattened slate-900 panel/canvas.
    expect(pill.color, AppColors.slate700);
  });

  testWidgets('pill renders on surfaces.card in light mode', (tester) async {
    await pump(tester, AppTheme.lightTheme);
    final pill = findPillMaterial(tester);
    // surfaces.card in light = #FFFFFF (the bumped slate-200 outline
    // gives the white-on-slate-50 pill its visible silhouette).
    expect(pill.color, const Color(0xFFFFFFFF));
  });
}

/// Minimal TaskSyncService impl — only the three ValueNotifiers the
/// pill (via SyncStateNotifier) listens to are real. Other methods
/// are routed through `noSuchMethod` so the test crashes loudly if
/// the widget ever starts calling them.
class _FakeTaskSyncService implements TaskSyncService {
  @override
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  @override
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier<DateTime?>(null);

  void _dispose() {
    isSyncing.dispose();
    lastError.dispose();
    lastSyncedAt.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
