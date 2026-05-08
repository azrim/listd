import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

/// Settings category
enum SettingsCategory { appearance, account, notifications }

/// Provider for selected settings category
final selectedSettingsCategoryProvider = StateProvider<SettingsCategory>(
  (ref) => SettingsCategory.appearance,
);

/// Settings screen with 2-panel sub-navigation.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedSettingsCategoryProvider);

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
                child: Row(
                  children: [
                    // Left panel: category navigation
                    SizedBox(
                      width: 240,
                      child: _CategoryPanel(selectedCategory: selectedCategory),
                    ),
                    // Vertical divider
                    Container(width: 1, color: AppColors.glassBorderSubtle),
                    // Right panel: settings content
                    Expanded(
                      child: _SettingsContent(category: selectedCategory),
                    ),
                  ],
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Settings',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Left panel: category navigation
class _CategoryPanel extends ConsumerWidget {
  final SettingsCategory selectedCategory;

  const _CategoryPanel({required this.selectedCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF0A1020),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETTINGS',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _CategoryItem(
            icon: Icons.palette_outlined,
            label: 'Appearance',
            isSelected: selectedCategory == SettingsCategory.appearance,
            onTap: () =>
                ref.read(selectedSettingsCategoryProvider.notifier).state =
                    SettingsCategory.appearance,
          ),
          _CategoryItem(
            icon: Icons.person_outline,
            label: 'Account',
            isSelected: selectedCategory == SettingsCategory.account,
            onTap: () =>
                ref.read(selectedSettingsCategoryProvider.notifier).state =
                    SettingsCategory.account,
          ),
          _CategoryItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            isSelected: selectedCategory == SettingsCategory.notifications,
            onTap: () =>
                ref.read(selectedSettingsCategoryProvider.notifier).state =
                    SettingsCategory.notifications,
          ),
        ],
      ),
    );
  }
}

/// Category navigation item
class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right panel: settings content for selected category
class _SettingsContent extends ConsumerWidget {
  final SettingsCategory category;

  const _SettingsContent({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getTitle(),
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSubtitle(),
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildContent(context, ref),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (category) {
      case SettingsCategory.appearance:
        return 'Appearance';
      case SettingsCategory.account:
        return 'Account';
      case SettingsCategory.notifications:
        return 'Notifications';
    }
  }

  String _getSubtitle() {
    switch (category) {
      case SettingsCategory.appearance:
        return 'Customize how listd looks on your device';
      case SettingsCategory.account:
        return 'Manage your account and sync settings';
      case SettingsCategory.notifications:
        return 'Configure when and how you receive alerts';
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    switch (category) {
      case SettingsCategory.appearance:
        return _AppearanceContent();
      case SettingsCategory.account:
        return _AccountContent();
      case SettingsCategory.notifications:
        return _NotificationsContent();
    }
  }
}

/// Appearance settings
class _AppearanceContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSection(title: 'Theme'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your preferred color scheme',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode,
                    label: 'Light',
                    isSelected: themeMode == ThemeMode.light,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 12),
                  _ThemeOption(
                    icon: Icons.dark_mode,
                    label: 'Dark',
                    isSelected: themeMode == ThemeMode.dark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 12),
                  _ThemeOption(
                    icon: Icons.settings_suggest,
                    label: 'System',
                    isSelected: themeMode == ThemeMode.system,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Theme option button
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Account settings
class _AccountContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final user = session?.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSection(title: 'Profile'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child:
                    user != null &&
                        user.userMetadata != null &&
                        user.userMetadata!['avatar_url'] != null
                    ? ClipOval(
                        child: Image.network(
                          user.userMetadata!['avatar_url'] as String,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null && user.userMetadata != null
                          ? (user.userMetadata!['name']?.toString() ??
                                user.email ??
                                'User')
                          : 'User',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SettingsSection(title: 'Sync'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-sync',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Automatically sync your tasks with the cloud',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ref.watch(autoSyncProvider),
                    onChanged: (value) =>
                        ref.read(autoSyncProvider.notifier).setEnabled(value),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SettingsSection(title: 'Danger Zone'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign out of your account',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your data will remain synced to the cloud.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Sign out',
                icon: Icons.logout,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.bgSurface,
                      title: Text(
                        'Sign out',
                        style: GoogleFonts.manrope(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to sign out?',
                        style: GoogleFonts.manrope(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.manrope(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Sign out', style: GoogleFonts.manrope()),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/auth');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Notifications settings
class _NotificationsContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSection(title: 'Task Reminders'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _NotificationToggle(
                icon: Icons.notifications_active,
                title: 'Due date reminders',
                subtitle: 'Get notified when tasks are due',
                value: true,
                onChanged: (value) {},
              ),
              const Divider(color: AppColors.glassBorderSubtle, height: 32),
              _NotificationToggle(
                icon: Icons.repeat,
                title: 'Repeat reminders',
                subtitle: 'Remind about recurring tasks',
                value: true,
                onChanged: (value) {},
              ),
              const Divider(color: AppColors.glassBorderSubtle, height: 32),
              _NotificationToggle(
                icon: Icons.star,
                title: 'Starred task alerts',
                subtitle: 'Notifications for important tasks',
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SettingsSection(title: 'Default Reminder Time'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder time',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'When new reminders are set',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '9:00 AM',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Notification toggle row
class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Settings section header
class _SettingsSection extends StatelessWidget {
  final String title;

  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
