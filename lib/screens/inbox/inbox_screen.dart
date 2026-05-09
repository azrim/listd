import '../../providers/ui_state_providers.dart';
import '_smart_bucket_screen.dart';

/// Inbox: open tasks that haven't been filed into a real list yet.
class InboxScreen extends SmartBucketScreen {
  InboxScreen({super.key})
    : super(title: 'Inbox', virtualId: SpecialListIds.inbox);
}
