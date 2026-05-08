import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync/task_sync_service.dart';
import 'task_lists_provider.dart'
    show taskDaoProvider, taskListDaoProvider, taskSyncServiceProvider;

/// Snapshot of the sync subsystem for the UI.
@immutable
class SyncStateSnapshot {
  const SyncStateSnapshot({
    required this.isSyncing,
    required this.pendingTaskLists,
    required this.pendingTasks,
    this.lastError,
    this.lastSyncedAt,
  });

  /// True while a sync cycle is actively running.
  final bool isSyncing;

  /// Number of task lists that have local edits pending push.
  final int pendingTaskLists;

  /// Number of tasks that have local edits pending push.
  final int pendingTasks;

  /// Last sync error message (null = no error since last success).
  final String? lastError;

  /// Timestamp of the last successful sync (null = never synced).
  final DateTime? lastSyncedAt;

  /// Total pending rows.
  int get totalPending => pendingTaskLists + pendingTasks;

  /// Whether everything in Drift is in sync with Supabase.
  bool get isInSync => totalPending == 0 && lastError == null;

  SyncStateSnapshot copyWith({
    bool? isSyncing,
    int? pendingTaskLists,
    int? pendingTasks,
    String? lastError,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return SyncStateSnapshot(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingTaskLists: pendingTaskLists ?? this.pendingTaskLists,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Streams the live count of pending Drift rows. Backed by dedicated
/// `SELECT COUNT(*)` queries in the DAOs so we don't have to materialize
/// the full row set just to count.
final pendingSyncCountsProvider = StreamProvider<({int lists, int tasks})>((
  ref,
) {
  final taskListDao = ref.watch(taskListDaoProvider);
  final taskDao = ref.watch(taskDaoProvider);

  final controller = StreamController<({int lists, int tasks})>.broadcast();
  int lists = 0;
  int tasks = 0;

  final listsSub = taskListDao.watchPendingSyncCount().listen((count) {
    lists = count;
    controller.add((lists: lists, tasks: tasks));
  });
  final tasksSub = taskDao.watchPendingSyncCount().listen((count) {
    tasks = count;
    controller.add((lists: lists, tasks: tasks));
  });

  ref.onDispose(() {
    listsSub.cancel();
    tasksSub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Combines the TaskSyncService ValueNotifiers + the pending counts
/// into a single snapshot the UI can render.
class SyncStateNotifier extends StateNotifier<SyncStateSnapshot> {
  SyncStateNotifier(this._service)
    : super(
        SyncStateSnapshot(
          isSyncing: _service.isSyncing.value,
          pendingTaskLists: 0,
          pendingTasks: 0,
          lastError: _service.lastError.value,
          lastSyncedAt: _service.lastSyncedAt.value,
        ),
      ) {
    _service.isSyncing.addListener(_onSyncing);
    _service.lastError.addListener(_onError);
    _service.lastSyncedAt.addListener(_onLastSynced);
  }

  final TaskSyncService _service;

  void _onSyncing() =>
      state = state.copyWith(isSyncing: _service.isSyncing.value);
  void _onError() {
    final err = _service.lastError.value;
    state = state.copyWith(lastError: err, clearError: err == null);
  }

  void _onLastSynced() =>
      state = state.copyWith(lastSyncedAt: _service.lastSyncedAt.value);

  /// Updates the pending counts from the [pendingSyncCountsProvider].
  void updatePending({required int lists, required int tasks}) {
    if (lists == state.pendingTaskLists && tasks == state.pendingTasks) return;
    state = state.copyWith(pendingTaskLists: lists, pendingTasks: tasks);
  }

  /// Triggers a full sync immediately (called by the manual sync button).
  Future<void> syncNow() async {
    try {
      await _service.syncAll();
    } catch (_) {
      // Already recorded on lastError; swallow so the button doesn't throw.
    }
  }

  @override
  void dispose() {
    _service.isSyncing.removeListener(_onSyncing);
    _service.lastError.removeListener(_onError);
    _service.lastSyncedAt.removeListener(_onLastSynced);
    super.dispose();
  }
}

/// Riverpod provider exposing the unified [SyncStateSnapshot].
///
/// Watches both the service's ValueNotifiers and the live pending-row
/// counts so the UI only ever has to subscribe to one provider.
final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, SyncStateSnapshot>((ref) {
      final service = ref.watch(taskSyncServiceProvider);
      final notifier = SyncStateNotifier(service);

      // Pipe pending-count updates into the same snapshot.
      ref.listen<AsyncValue<({int lists, int tasks})>>(
        pendingSyncCountsProvider,
        (_, next) {
          next.whenData(
            (counts) => notifier.updatePending(
              lists: counts.lists,
              tasks: counts.tasks,
            ),
          );
        },
        fireImmediately: true,
      );
      return notifier;
    });
