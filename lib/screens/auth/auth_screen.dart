import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth/google_auth_service.dart';
import '../../services/auth/token_manager.dart';
import '../../services/supabase/supabase_client_service.dart';
import '../../widgets/app_logo.dart';

/// Auth screen — minimal centered card. No orbs, no pulsing glow, no
/// gradients; the only emphasis is the indigo `FilledButton`.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final authService = GoogleAuthService(client);
      await authService.authorize();
    } catch (e) {
      if (mounted) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: scheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(
                  size: 56,
                ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05),
                const SizedBox(height: 24),
                Text(
                  'Listd',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    height: 40 / 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.64,
                    color: scheme.onSurface,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 320.ms),
                const SizedBox(height: 6),
                Text(
                  'Capture, complete, sync.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ).animate().fadeIn(delay: 160.ms, duration: 320.ms),
                const SizedBox(height: 40),
                SizedBox(
                  width: 240,
                  height: 32,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.g_mobiledata, size: 18),
                    label: Text(
                      _isLoading ? 'Signing in…' : 'Continue with Google',
                    ),
                  ),
                ).animate().fadeIn(delay: 240.ms, duration: 320.ms),
                const SizedBox(height: 12),
                Text(
                  'By continuing you agree to our Terms.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 16 / 11,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
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
