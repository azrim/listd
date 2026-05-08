import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth/google_auth_service.dart';
import '../../services/auth/token_manager.dart';
import '../../services/supabase/supabase_client_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

/// Authentication screen with glassmorphism UI
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final authService = GoogleAuthService(client);
      await authService.authorize();
      // After authorize completes, auth state should be updated
      // The widget will rebuild due to authNotifierProvider change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state - navigate to home when authenticated
    final authState = ref.watch(authNotifierProvider);

    if (authState is AuthAuthenticated) {
      // Auth succeeded, navigate to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          _buildOrbs(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 24),
                  Text(
                        'listd',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  Text(
                    'Your tasks, beautifully organized',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 48),
                  GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            GradientButton(
                              label: _isLoading
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                              icon: Icons.g_mobiledata,
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              width: 260,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'By continuing you agree to our Terms',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withAlpha(51),
                          AppColors.primary.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withAlpha(31),
                  AppColors.primaryLight.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(102),
                blurRadius: 30 + (_pulseAnimation.value * 10),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.primary.withAlpha(51),
                blurRadius: 60 + (_pulseAnimation.value * 15),
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 40,
          ),
        );
      },
    );
  }
}
