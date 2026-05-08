import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

/// Folders screen with grid layout.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060818), Color(0xFF0D1535), Color(0xFF162040)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: taskListsAsync.when(
                  data: (taskLists) => _buildGrid(context, ref, taskLists),
                  loading: () => _buildLoadingGrid(),
                  error: (error, _) => _buildError(context, ref, error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.glassBorderSubtle)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_outlined,
            color: AppColors.textPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Folders',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GradientButton(
            label: 'Create New Folder',
            icon: Icons.add,
            onPressed: () => _showCreateFolderDialog(context),
            width: 180,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<TaskList> taskLists,
  ) {
    // Folder accent colors cycling
    final accentColors = [
      AppColors.primary, // indigo
      const Color(0xFF4CAF50), // green
      const Color(0xFFFFCA28), // amber
      const Color(0xFFEF5350), // red
      const Color(0xFFE91E63), // pink
      const Color(0xFF009688), // teal
    ];

    final itemCount = taskLists.length + 1; // +1 for "Create Folder" card

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == taskLists.length) {
          // Last item: Create Folder card with dashed border
          return _CreateFolderCard(
            onTap: () => _showCreateFolderDialog(context),
          );
        }

        final taskList = taskLists[index];
        final accentColor = accentColors[index % accentColors.length];
        return _FolderCard(
          taskList: taskList,
          accentColor: accentColor,
          onTap: () => _navigateToTasks(context, taskList),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return GlassCard(
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Failed to load folders',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () =>
                  ref.read(taskListsNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: Text(
                'Retry',
                style: GoogleFonts.manrope(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'Create folder',
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: GoogleFonts.manrope(color: AppColors.textHint),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Create', style: GoogleFonts.manrope()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Create folder via provider
      // For now, just navigate to the new folder
    }
  }

  void _navigateToTasks(BuildContext context, TaskList taskList) {
    context.go(
      '/tasks/${Uri.encodeComponent(taskList.id)}?title=${Uri.encodeComponent(taskList.title)}',
    );
  }
}

/// Folder card with colored accent border
class _FolderCard extends StatelessWidget {
  final TaskList taskList;
  final Color accentColor;
  final VoidCallback onTap;

  const _FolderCard({
    required this.taskList,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top accent border (4px)
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Folder icon in rounded square
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.folder, color: accentColor, size: 24),
                  ),
                  const Spacer(),
                  // Folder name
                  Text(
                    taskList.title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Active tasks count
                  Text(
                    'Active tasks',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create folder card with dashed border
class _CreateFolderCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateFolderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create Folder',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed border
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Empty - we use Container border instead
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
