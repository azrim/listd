import '../../providers/ui_state_providers.dart';
import '../inbox/_smart_bucket_screen.dart';

/// Important: every starred non-completed task across every list.
class ImportantScreen extends SmartBucketScreen {
  ImportantScreen({super.key})
    : super(title: 'Important', virtualId: SpecialListIds.important);
}
