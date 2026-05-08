import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/daos/task_dao.dart';
import '../models/task.dart';
import '../services/auth/token_manager.dart';
import 'task_lists_provider.dart'
    show
        databaseProvider,
        supabaseTasksProviderProvider,
        taskListsNotifierProvider;

/// Provider for the [TaskDao].
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskDao(db);
});

/// Notifier for managing tasks state for a specific task list.
///
/// This is the **single source of truth** for tasks of [taskListId]. It
/// hydrates from the local Drift cache instantly, then performs a
/// background sync against Supabase. All mutations refresh remote and
/// fall through into Drift on a best-effort basis.
class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TasksNotifier({required Ref ref, required this.taskListId})
    : _ref = ref,
      super(const AsyncValue.loading()) {
    // Synthetic lists ("@my-day", "@important") carry no real tasks; their
    // contents come from `allTasksProvider` and are filtered in the UI layer.
    if (taskListId.startsWith('@')) {
      state = const AsyncValue.data([]);
      return;
    }
    _hydrateFromCache().then((_) => _syncFromRemote());
  }

  final Ref _ref;
  final String taskListId;

  Future<void> _hydrateFromCache() async {
    try {
      final dao = _ref.read(taskDaoProvider);
      final cached = await dao.getTasksByListId(taskListId);
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached.map((e) => e.toDomain()).toList());
      }
    } catch (_) {
      // Drift unavailable on this platform — keep loading state and let
      // remote populate.
    }
  }

  Future<void> _syncFromRemote() async {
    final authState = _ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      if (state is AsyncLoading) {
        state = const AsyncValue.data([]);
      }
      return;
    }

    try {
      final provider = _ref.read(supabaseTasksProviderProvider);
      final remoteTasks = await provider.getTasks(taskListId);
      state = AsyncValue.data(remoteTasks);
      // Best-effort cache write — never let Drift errors clobber state.
      try {
        if (remoteTasks.isNotEmpty) {
          await _ref.read(taskDaoProvider).upsertTasks(remoteTasks);
        }
      } catch (_) {}
    } catch (e, st) {
      // Only surface the error if we have nothing to show.
      if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Re-fetch from Supabase. Use after external mutations.
  Future<void> refresh() => _syncFromRemote();

  /// Backwards-compat alias for callers that say `syncFromRemote()`.
  Future<void> syncFromRemote() => _syncFromRemote();

  Future<void> createTask(Task task) async {
    final authState = _ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final taskWithId = task.id.isEmpty
        ? task.copyWith(id: const Uuid().v4())
        : task;

    final provider = _ref.read(supabaseTasksProviderProvider);
    await provider.createTask(taskListId, taskWithId);
    await _syncFromRemote();
  }

  Future<void> updateTask(Task task) async {
    final authState = _ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final provider = _ref.read(supabaseTasksProviderProvider);
    await provider.updateTask(taskListId, task);
    await _syncFromRemote();
  }

  Future<void> toggleComplete(Task task) async {
    final newStatus = task.isCompleted ? 'needsAction' : 'completed';
    await updateTask(task.copyWith(status: newStatus));
  }

  Future<void> deleteTask(String taskId) async {
    final authState = _ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final provider = _ref.read(supabaseTasksProviderProvider);
    await provider.deleteTask(taskListId, taskId);
    await _syncFromRemote();
  }
}

/// Family provider for [TasksNotifier]. **The** source of truth for
/// per-list task state. UI code reads from here directly rather than
/// going around it via stream / future providers.
final tasksNotifierProvider =
    StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>(
      (ref, taskListId) => TasksNotifier(ref: ref, taskListId: taskListId),
    );

/// Aggregates tasks across **every** task list. Used by Planned and
/// other cross-list views so they don't have to thread through every
/// list provider individually. Returns loading until at least one list
/// has data; surfaces the first error if all lists fail.
final allTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final listsAsync = ref.watch(taskListsNotifierProvider);

  return listsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (taskLists) {
      final aggregate = <Task>[];
      var anyLoading = false;
      Object? firstError;
      StackTrace? firstStack;

      for (final list in taskLists) {
        final tasksAsync = ref.watch(tasksNotifierProvider(list.id));
        tasksAsync.when(
          data: aggregate.addAll,
          loading: () => anyLoading = true,
          error: (e, st) {
            firstError ??= e;
            firstStack ??= st;
          },
        );
      }

      if (aggregate.isNotEmpty) {
        return AsyncValue.data(aggregate);
      }
      if (anyLoading) {
        return const AsyncValue.loading();
      }
      if (firstError != null) {
        return AsyncValue.error(firstError!, firstStack ?? StackTrace.empty);
      }
      return const AsyncValue.data(<Task>[]);
    },
  );
});
