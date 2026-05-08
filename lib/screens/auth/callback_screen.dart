import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth/token_manager.dart';

/// OAuth callback handler — minimal centered status per the 2026 spec.
///
/// Supabase handles the OAuth callback via deep link; this screen just
/// listens for auth state changes and redirects.
class CallbackScreen extends ConsumerStatefulWidget {
  const CallbackScreen({super.key});

  @override
  ConsumerState<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends ConsumerState<CallbackScreen> {
  bool _hasNavigated = false;

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
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate(authState);
    });

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Signing you in…',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
