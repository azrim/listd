import '../../providers/today_provider.dart';
import '../inbox/_smart_bucket_screen.dart';

/// Planned: anything with a due date or a reminder.
class PlannedScreen2027 extends SmartBucketScreen {
  PlannedScreen2027({super.key})
    : super(title: 'Planned', provider: plannedTasksProvider);
}
