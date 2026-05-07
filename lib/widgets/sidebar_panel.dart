import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the currently selected task list ID
final selectedTaskListIdProvider = StateProvider<String?>((ref) => null);

/// Left sidebar panel with task lists
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedListId = ref.watch(selectedTaskListIdProvider);

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/listd_logo.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.check_circle,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Listd',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main sections (My Day, Important, Planned)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader(title: 'My Day'),
                _SidebarItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'My Day',
                  iconColor: Colors.orange,
                  isSelected: selectedListId == 'myday',
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          'myday',
                ),
                _SidebarItem(
                  icon: Icons.star_outline,
                  title: 'Important',
                  iconColor: colorScheme.primary,
                  isSelected: selectedListId == 'important',
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          'important',
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Planned',
                  iconColor: colorScheme.tertiary,
                  isSelected: selectedListId == 'planned',
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          'planned',
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Custom lists section
                _SectionHeader(title: 'My Lists'),
                _SidebarItem(
                  icon: Icons.inbox,
                  title: 'Tasks',
                  isSelected: selectedListId == 'default',
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          'default',
                ),
                // Placeholder for custom lists
                _SidebarItem(
                  icon: Icons.list,
                  title: 'Shopping',
                  subtitle: '3',
                  isSelected: selectedListId == 'shopping',
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          'shopping',
                ),
                _SidebarItem(
                  icon: Icons.work_outline,
                  title: 'Work',
                  subtitle: '5',
                  isSelected: selectedListId == 'work',
                  onTap: () =>
                      ref.read(selectedTaskListIdProvider.notifier).state =
                          'work',
                ),
              ],
            ),
          ),

          // Bottom section with "+ New list" button
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () {
                // TODO: Implement new list creation
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New list'),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.isSelected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withAlpha(128)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
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
