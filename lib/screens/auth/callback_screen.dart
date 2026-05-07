import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth/token_manager.dart';
import '../../theme/app_colors.dart';

/// OAuth callback handler screen with glassmorphism loading animation.
///
/// With Supabase, this screen just needs to listen for auth state changes.
/// Supabase handles the OAuth callback via deep link automatically.
class CallbackScreen extends ConsumerStatefulWidget {
  const CallbackScreen({super.key});

  @override
  ConsumerState<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends ConsumerState<CallbackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _checkAndNavigate(AuthState authState) {
    if (_hasNavigated) return;

    switch (authState) {
      case AuthAuthenticated():
        if (mounted) {
          _hasNavigated = true;
          context.go('/');
        }
      case AuthUnauthenticated():
      case AuthError():
        if (mounted) {
          _hasNavigated = true;
          context.go('/auth');
        }
      case AuthLoading():
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state and navigate when it changes
    final authState = ref.watch(authNotifierProvider);

    // Check initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate(authState);
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          // Loading content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing circle
                AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 80 + (_pulseAnimation.value * 20),
                          height: 80 + (_pulseAnimation.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(
                              (76 + (_pulseAnimation.value * 50)).round(),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(
                                  (102 * _pulseAnimation.value).round(),
                                ),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        );
                      },
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1500.ms)
                    .then()
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 32),
                // Loading text
                Text(
                  'Connecting to Supabase...',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 24),
                // Progress indicator
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.glassWhite,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
