import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/ui_state_providers.dart';
import '../../widgets/context_menu.dart';
import '../../widgets/rename_dialog.dart';

/// "Folders" bento grid screen — visual list of task lists.
class ManageFoldersScreen extends ConsumerWidget {
  const ManageFoldersScreen({super.key});

  /// Deterministic accent color per folder, cycled by index.
  static const _accents = <Color>[
    Color(0xFF1A146B), // Indigo
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF1E3A8A), // Deep blue
    Color(0xFF38BDF8), // Sky
    Color(0xFFEC4899), // Pink
  ];

  /// Pick an icon from the title prefix as a stable visual token.
  IconData _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('work')) return Icons.work_outline;
    if (t.contains('shop')) return Icons.shopping_cart_outlined;
    if (t.contains('fit') || t.contains('gym')) return Icons.fitness_center;
    if (t.contains('proj')) return Icons.rocket_launch_outlined;
    if (t.contains('home')) return Icons.home_outlined;
    if (t.contains('travel') || t.contains('trip')) return Icons.flight;
    if (t.contains('study') || t.contains('school')) return Icons.school;
    return Icons.person_outline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final listsAsync = ref.watch(taskListsNotifierProvider);
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref, scheme),
              const SizedBox(height: 24),
              Expanded(
                child: listsAsync.when(
                  data: (lists) =>
                      _buildGrid(context, ref, scheme, lists, tasksAsync),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildError(scheme, e, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Folders',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Organize your tasks across different projects and contexts.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => _showCreateDialog(context, ref),
          icon: const Icon(Icons.create_new_folder_outlined, size: 18),
          label: const Text('Create New Folder'),
        ),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    ColorScheme scheme,
    List<TaskList> lists,
    AsyncValue<List<dynamic>> tasksAsync,
  ) {
    final tasks = tasksAsync.valueOrNull ?? const [];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3 columns above 900px, 2 columns above 600px, else 1 column.
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.55,
          ),
          itemCount: lists.length + 1,
          itemBuilder: (context, index) {
            if (index == lists.length) {
              return _CreateFolderTile(
                onTap: () => _showCreateDialog(context, ref),
              );
            }
            final list = lists[index];
            final accent = _accents[index % _accents.length];
            final activeCount = tasks
                .where(
                  (t) =>
                      // ignore: avoid_dynamic_calls
                      t.taskListId == list.id && t.isCompleted == false,
                )
                .length;
            return _FolderCard(
              accent: accent,
              icon: _iconFor(list.title),
              title: list.title,
              activeTaskCount: activeCount,
              onTap: () {
                ref.read(selectedTaskListIdProvider.notifier).state = list.id;
                Navigator.of(context).maybePop();
              },
              onSecondaryTapDown: (details) => _showFolderContextMenu(
                context,
                ref,
                details.globalPosition,
                list,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(ColorScheme scheme, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 48),
          const SizedBox(height: 12),
          Text(
            'Could not load folders',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(taskListsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFolderContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
    TaskList list,
  ) {
    showListdContextMenu(context, globalPosition, [
      ListdContextMenuItem(
        icon: Icons.drive_file_rename_outline,
        label: 'Rename',
        onTap: () async {
          final next = await showRenameDialog(
            context,
            title: 'Rename folder',
            initial: list.title,
            confirmLabel: 'Rename',
            hintText: 'Folder name',
          );
          if (next == null || next == list.title) return;
          await ref
              .read(taskListsNotifierProvider.notifier)
              .updateTaskList(list.copyWith(title: next));
        },
      ),
      const ListdContextMenuDivider(),
      ListdContextMenuItem(
        icon: Icons.delete_outline,
        label: 'Delete folder',
        destructive: true,
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final confirmed = await showDestructiveConfirm(
            context,
            title: 'Delete folder?',
            message:
                'Delete "${list.title}" and all of its tasks? This can\'t be undone.',
            confirmLabel: 'Delete',
          );
          if (confirmed != true) return;
          await ref
              .read(taskListsNotifierProvider.notifier)
              .deleteTaskList(list.id);
          messenger.showSnackBar(
            SnackBar(content: Text('Deleted "${list.title}"')),
          );
        },
      ),
    ]);
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: Navigator.of(context).pop,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref
          .read(taskListsNotifierProvider.notifier)
          .createTaskList(result.trim());
    }
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.activeTaskCount,
    required this.onTap,
    this.onSecondaryTapDown,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final int activeTaskCount;
  final VoidCallback onTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onSecondaryTapDown: onSecondaryTapDown,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeTaskCount Active Task'
                        '${activeTaskCount == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateFolderTile extends StatelessWidget {
  const _CreateFolderTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DottedBorder(
          color: scheme.outline,
          radius: 16,
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add,
                      color: scheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create Folder',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
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

/// Lightweight dashed-border container — avoids pulling in dotted_border pkg.
class DottedBorder extends StatelessWidget {
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 8,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashed = _dashedPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashedPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        dest.addPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          Offset.zero,
        );
        distance = next + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
