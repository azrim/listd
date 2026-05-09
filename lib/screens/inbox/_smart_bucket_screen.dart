import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task.dart';
import '../../providers/ui_state_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';

/// Shared canvas for smart buckets that don't need a calendar strip
/// (Inbox / Important / Planned / All Tasks).
///
/// Mirrors the Today layout: 720 px max-width canvas, Inter H1 headline,
/// list of TaskCard islands. Newsreader is reserved for the Today date
/// headline, empty-state lines, and the About screen — every other
/// heading uses Inter 24/700 (`ListdTypography.h1`).
class SmartBucketScreen extends ConsumerWidget {
  // Subclasses pass non-const Provider literals, so this constructor
  // can't be `const` — silencing the lint rather than chasing it.
  // ignore: prefer_const_constructors_in_immutables
  SmartBucketScreen({super.key, required this.title, required this.provider});

  final String title;
  final ProviderListenable<AsyncValue<List<Task>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.card ?? scheme.surface;
    final typography = theme.extension<ListdTypography>();
    final tasksAsync = ref.watch(provider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720 + 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant, width: 1),
                boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      title,
                      style:
                          typography?.h1 ??
                          GoogleFonts.inter(
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.48,
                            color: scheme.onSurface,
                          ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
                  Expanded(
                    child: tasksAsync.when(
                      loading: () => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Couldn\'t load: $e',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return _Empty(title: title, scheme: scheme);
                        }
                        return _List(tasks: tasks);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedId = ref.watch(expandedTaskIdProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          key: ValueKey<String>(task.id),
          task: task,
          listId: task.taskListId,
          isExpanded: expandedId == task.id,
          isSelected: selectedTaskId == task.id,
          onToggleExpand: () {
            final notifier = ref.read(expandedTaskIdProvider.notifier);
            notifier.state = expandedId == task.id ? null : task.id;
            ref.read(selectedTaskIdProvider.notifier).state = task.id;
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.scheme});

  final String title;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nothing in $title.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
