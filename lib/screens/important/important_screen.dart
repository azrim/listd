import '../../providers/today_provider.dart';
import '../inbox/_smart_bucket_screen.dart';

/// Important: every starred non-completed task.
class ImportantScreen extends SmartBucketScreen {
  ImportantScreen({super.key})
    : super(title: 'Important', provider: importantTasksProvider);
}
