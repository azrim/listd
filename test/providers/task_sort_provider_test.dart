import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:listd/models/task_sort_mode.dart';
import 'package:listd/providers/task_sort_provider.dart';

/// Pins the SharedPreferences round-trip for the app-wide task sort
/// preference. Default is [TaskSortMode.manual] (zero-regression on
/// existing installs); changes write through; restart re-hydrates.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('defaults to TaskSortMode.manual on first launch', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(taskSortModeProvider), TaskSortMode.manual);
  });

  test('setMode persists across rebuilds', () async {
    final c1 = ProviderContainer();
    c1.read(taskSortModeProvider.notifier).setMode(TaskSortMode.dueDate);
    expect(c1.read(taskSortModeProvider), TaskSortMode.dueDate);
    // Wait for the async write before disposing — without it the
    // platform store may flush after we tear down.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    c1.dispose();

    // Fresh container hydrates from the same in-memory store.
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    // Hydration is async — wait one tick for it to land.
    c2.read(taskSortModeProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c2.read(taskSortModeProvider), TaskSortMode.dueDate);
  });

  test('unknown persisted key falls back to manual', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'listd.taskSortMode': 'gibberish',
        });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(taskSortModeProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(taskSortModeProvider), TaskSortMode.manual);
  });
}
