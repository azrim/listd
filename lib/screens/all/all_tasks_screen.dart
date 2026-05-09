import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../inbox/_smart_bucket_screen.dart';

final _allTasksFilteredProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allAsync = ref.watch(allTasksProvider);
  return allAsync.whenData(
    (tasks) => tasks.where((t) => !t.isCompleted).toList(),
  );
});

/// All Tasks: every non-completed task across every list.
class AllTasksScreen extends SmartBucketScreen {
  AllTasksScreen({super.key})
    : super(title: 'All Tasks', provider: _allTasksFilteredProvider);
}
