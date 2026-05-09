import '../../providers/ui_state_providers.dart';
import '../inbox/_smart_bucket_screen.dart';

/// Planned: anything with a due date or a reminder.
class PlannedScreen2027 extends SmartBucketScreen {
  PlannedScreen2027({super.key})
    : super(title: 'Planned', virtualId: SpecialListIds.planned);
}
