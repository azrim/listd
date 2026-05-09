import '../../providers/today_provider.dart';
import '_smart_bucket_screen.dart';

/// Inbox: tasks that haven't been filed into a real list yet.
class InboxScreen extends SmartBucketScreen {
  InboxScreen({super.key})
    : super(title: 'Inbox', provider: inboxTasksProvider);
}
