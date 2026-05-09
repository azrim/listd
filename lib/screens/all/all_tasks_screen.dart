import '../../providers/ui_state_providers.dart';
import '../inbox/_smart_bucket_screen.dart';

/// All Tasks: every task across every list (the underlying virtual
/// `@tasks` filter passes everything through unchanged so completed
/// rows still render with strikethrough per `03_list_view_light.png`).
class AllTasksScreen extends SmartBucketScreen {
  AllTasksScreen({super.key})
    : super(title: 'All Tasks', virtualId: SpecialListIds.tasks);
}
