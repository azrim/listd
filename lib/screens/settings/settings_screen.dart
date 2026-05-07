import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

/// Settings screen with glassmorphism UI
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
          _buildGlassAppBar(context),
          // Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              children: [
                // Appearance section
                _SectionHeader(
                  title: 'Appearance',
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 12),
                _ThemeSelectorCard(
                      currentMode: themeMode,
                      onChanged: (mode) => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(mode),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 32),

                // Account section
                _SectionHeader(
                  title: 'Account',
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 12),
                _AccountCard()
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 32),

                // About section
                _SectionHeader(
                  title: 'About',
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                const SizedBox(height: 12),
                _AboutCard()
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideY(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.go('/'),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Theme selector card with pill toggle
class _ThemeSelectorCard extends StatelessWidget {
  const _ThemeSelectorCard({
    required this.currentMode,
    required this.onChanged,
  });

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(31),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Theme',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.glassBorder.withAlpha(64),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _ThemePill(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => onChanged(ThemeMode.light),
                ),
                _ThemePill(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => onChanged(ThemeMode.dark),
                ),
                _ThemePill(
                  label: 'System',
                  icon: Icons.settings_suggest_outlined,
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => onChanged(ThemeMode.system),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme pill toggle button
class _ThemePill extends StatelessWidget {
  const _ThemePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Account card with sign out
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        children: [
          // Google account status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withAlpha(31),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Account',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connected',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: AppColors.glassBorder.withAlpha(64)),
          const SizedBox(height: 16),
          // Sign out button
          GestureDetector(
            onTap: () => _showSignOutDialog(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(31),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.danger,
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

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withAlpha(31),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign out',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out? Your local data will be preserved.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign out',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _signOut(context, ref);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.logout();

      if (context.mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

/// About card
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          // Version row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(31),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1.0.0',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.glassBorder.withAlpha(64)),
          const SizedBox(height: 16),
          // About button
          GestureDetector(
            onTap: () => _showAboutDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.glassBorder.withAlpha(64),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.open_in_new,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'About Listd',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Future<void> _showAboutDialog(BuildContext context) async {
    showAboutDialog(
      context: context,
      applicationName: 'Listd',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      applicationLegalese: '© 2024 Listd\nBuilt with Flutter',
      children: [
        const SizedBox(height: 16),
        Text(
          'Listd is a task management app that integrates with Google Tasks. '
          'Organize your tasks and keep them in sync across all your devices.',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
