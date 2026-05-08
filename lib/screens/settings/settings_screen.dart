import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// Settings category in the left sub-nav.
enum SettingsCategory { account, notifications, appearance, workspace }

extension on SettingsCategory {
  String get label {
    switch (this) {
      case SettingsCategory.account:
        return 'Account';
      case SettingsCategory.notifications:
        return 'Notifications';
      case SettingsCategory.appearance:
        return 'Appearance';
      case SettingsCategory.workspace:
        return 'Workspace';
    }
  }

  IconData get icon {
    switch (this) {
      case SettingsCategory.account:
        return Icons.person_outline;
      case SettingsCategory.notifications:
        return Icons.notifications_outlined;
      case SettingsCategory.appearance:
        return Icons.palette_outlined;
      case SettingsCategory.workspace:
        return Icons.workspaces_outlined;
    }
  }
}

/// Provider for selected settings category.
final selectedSettingsCategoryProvider = StateProvider<SettingsCategory>(
  (ref) => SettingsCategory.appearance,
);

/// Settings screen with 2-pane sub-navigation.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(selectedSettingsCategoryProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _CategoryPanel(selected: selected),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: _SettingsContent(category: selected)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: scheme.onSurface),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Settings',
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPanel extends ConsumerWidget {
  const _CategoryPanel({required this.selected});

  final SettingsCategory selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final category in SettingsCategory.values)
            _CategoryItem(
              category: category,
              isSelected: selected == category,
              onTap: () =>
                  ref.read(selectedSettingsCategoryProvider.notifier).state =
                      category,
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final SettingsCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                category.icon,
                size: 20,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                category.label,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: switch (category) {
        SettingsCategory.appearance => const _AppearanceContent(),
        SettingsCategory.account => const _AccountContent(),
        SettingsCategory.notifications => const _NotificationsContent(),
        SettingsCategory.workspace => const _WorkspaceContent(),
      },
    );
  }
}

/// Card container styled per Stitch design.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _AppearanceContent extends ConsumerWidget {
  const _AppearanceContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Appearance',
                subtitle: 'Customize the visual style of your workspace.',
              ),
              const SizedBox(height: 24),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Switch to a darker interface for low-light environments.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (value) => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 24),
              Text(
                'Theme Color',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              const _ThemeColorPicker(),
              const SizedBox(height: 24),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 24),
              Text(
                'Font Size',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Aa',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Expanded(child: Slider(value: 0.5, onChanged: null)),
                  Text(
                    'Aa',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // IntrinsicHeight gives the Row's stretch alignment a finite vertical
        // constraint when nested inside a SingleChildScrollView. Without it
        // the Row gets BoxConstraints(h=Infinity) and asserts at layout time.
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _ProfileDetailsCard()),
              SizedBox(width: 16),
              Expanded(child: _AlertPreferencesCard()),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings saved'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}

class _ThemeColorPicker extends StatelessWidget {
  const _ThemeColorPicker();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final swatches = <Color>[
      scheme.primary,
      const Color(0xFF38BDF8),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < swatches.length; i++)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: swatches[i],
              borderRadius: BorderRadius.circular(8),
              border: i == 0
                  ? Border.all(color: scheme.primary, width: 2)
                  : null,
            ),
            child: i == 0 ? Icon(Icons.check, color: scheme.onPrimary) : null,
          ),
      ],
    );
  }
}

class _ProfileDetailsCard extends ConsumerWidget {
  const _ProfileDetailsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.session.user : null;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final name = (user?.userMetadata?['name'] as String?) ?? user?.email ?? '';
    final email = user?.email ?? '';

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile Details',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primary.withValues(alpha: 0.18),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: scheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'User' : name,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: null,
              child: Text(
                'Edit Profile',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertPreferencesCard extends StatelessWidget {
  const _AlertPreferencesCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Alert Preferences',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(value: true, onChanged: (_) {}),
              ),
              const SizedBox(width: 8),
              Text(
                'Email Summaries',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(value: false, onChanged: (_) {}),
              ),
              const SizedBox(width: 8),
              Text(
                'Push Notifications',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: null,
              child: Text(
                'Manage All',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountContent extends ConsumerWidget {
  const _AccountContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.session.user : null;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Account',
                subtitle: 'Manage your account and sync settings.',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primary.withValues(alpha: 0.18),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, color: scheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?.userMetadata?['name'] as String?) ??
                              user?.email ??
                              'User',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email!,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.sync, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-sync',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Automatically sync your tasks with the cloud',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ref.watch(autoSyncProvider),
                    onChanged: (value) =>
                        ref.read(autoSyncProvider.notifier).setEnabled(value),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danger Zone',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign out of your account. Your data will remain synced to the cloud.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _confirmSignOut(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Sign out',
            style: GoogleFonts.manrope(color: scheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.manrope(color: scheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }
}

class _NotificationsContent extends ConsumerStatefulWidget {
  const _NotificationsContent();

  @override
  ConsumerState<_NotificationsContent> createState() =>
      _NotificationsContentState();
}

class _NotificationsContentState extends ConsumerState<_NotificationsContent> {
  bool _dueDateReminders = true;
  bool _repeatReminders = true;
  bool _starredAlerts = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Notifications',
            subtitle: 'Configure when and how you receive alerts.',
          ),
          const SizedBox(height: 20),
          _NotificationToggle(
            icon: Icons.notifications_active_outlined,
            title: 'Due date reminders',
            subtitle: 'Get notified when tasks are due',
            value: _dueDateReminders,
            onChanged: (value) => setState(() => _dueDateReminders = value),
          ),
          Divider(color: scheme.outlineVariant, height: 24),
          _NotificationToggle(
            icon: Icons.repeat,
            title: 'Repeat reminders',
            subtitle: 'Remind about recurring tasks',
            value: _repeatReminders,
            onChanged: (value) => setState(() => _repeatReminders = value),
          ),
          Divider(color: scheme.outlineVariant, height: 24),
          _NotificationToggle(
            icon: Icons.star_outline,
            title: 'Starred task alerts',
            subtitle: 'Notifications for important tasks',
            value: _starredAlerts,
            onChanged: (value) => setState(() => _starredAlerts = value),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Workspace',
            subtitle: 'Configure your workspace defaults.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.workspaces_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Workspace customization is coming soon.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
