import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/task_list.dart';
import '../../providers/task_lists_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

/// Screen displaying all task lists with glassmorphism UI.
class TaskListsScreen extends ConsumerWidget {
  const TaskListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListsAsync = ref.watch(taskListsStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          // Custom glass app bar
          _buildGlassAppBar(context, ref),
          // Content
          SafeArea(
            child: taskListsAsync.when(
              data: (taskLists) => _buildTaskList(context, ref, taskLists),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildError(context, ref, error),
            ),
          ),
          // FAB
          Positioned(
            right: 24,
            bottom: 24,
            child: _buildFAB(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(153),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'listd',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync, color: AppColors.textSecondary),
                onPressed: () => ref.read(taskListsNotifierProvider.notifier).refresh(),
                tooltip: 'Sync',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                onPressed: () => context.go('/settings'),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskList> taskLists,
  ) {
    if (taskLists.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final notifier = ref.read(taskListsNotifierProvider.notifier);
        await notifier.refresh();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        itemCount: taskLists.length,
        itemBuilder: (context, index) {
          final taskList = taskLists[index];
          return _TaskListGlassTile(
            taskList: taskList,
            onTap: () => _navigateToTasks(context, taskList),
          )
              .animate()
              .fadeIn(delay: (index * 50).ms, duration: 300.ms)
              .slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(31),
                ),
                child: const Icon(
                  Icons.list_alt_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No task lists found',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Google Tasks will appear here',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => ref.read(taskListsNotifierProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: Text(
                  'Sync from Google',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.bgSurface,
          highlightColor: AppColors.bgMid,
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(26),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withAlpha(26),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withAlpha(26),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms);
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withAlpha(31),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load task lists',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => ref.read(taskListsNotifierProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: Text(
                  'Retry',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFAB(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => ref.read(taskListsNotifierProvider.notifier).refresh(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  void _navigateToTasks(BuildContext context, TaskList taskList) {
    context.go(
      '/tasks/${Uri.encodeComponent(taskList.id)}?title=${Uri.encodeComponent(taskList.title)}',
    );
  }
}

/// Glass tile for task list item
class _TaskListGlassTile extends StatelessWidget {
  const _TaskListGlassTile({
    required this.taskList,
    this.onTap,
  });

  final TaskList taskList;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(31),
            ),
            child: const Icon(
              Icons.list_alt,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskList.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated ${_formatDate(taskList.updated)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}