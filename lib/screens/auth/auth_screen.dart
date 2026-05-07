import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth/google_auth_service.dart';
import '../../services/auth/token_manager.dart';

/// Authentication screen with Google sign-in button.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/listd_logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if logo fails to load
                    return Icon(
                      Icons.check_circle_outline,
                      size: 120,
                      color: colorScheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // App title
              Text(
                'Listd',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your tasks, organized',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              // Google sign-in button
              FilledButton.icon(
                onPressed: () => _signInWithGoogle(context, ref),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Info text
              Text(
                'Sign in to sync your Google Tasks',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final authService = GoogleAuthService(secureStorage: secureStorage);

      // Perform OAuth authorization (opens browser, waits for callback, stores tokens)
      final result = await authService.authorize();

      // Update auth state with the new tokens
      final authNotifier = ref.read(authNotifierProvider.notifier);
      authNotifier.setAuthenticated(result.accessToken, result.expiresAt);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
