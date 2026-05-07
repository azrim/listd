import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client_service.dart';

/// Represents the authentication state of the application.
sealed class AuthState {
  const AuthState();
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated with a Supabase session.
class AuthAuthenticated extends AuthState {
  final Session session;

  const AuthAuthenticated(this.session);

  /// Check if token will expire within the specified minutes.
  bool willExpireWithin(Duration duration) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return expiryTime.difference(DateTime.now()) < duration;
  }
}

/// Authentication is currently loading/initializing.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentication failed with an error.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

/// Notifier for managing authentication state via Supabase.
///
/// Supabase handles all token management, refresh, and storage automatically.
/// This notifier just bridges Supabase's auth state to our app's AuthState.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._client) : super(const AuthLoading()) {
    _init();
  }

  final SupabaseClient _client;

  void _init() {
    // Listen to Supabase auth state changes
    _client.auth.onAuthStateChange.listen((event) {
      switch (event) {
        case AuthChangeEvent.signedIn:
          final session = event.session;
          if (session != null) {
            state = AuthAuthenticated(session);
          } else {
            state = const AuthUnauthenticated();
          }
        case AuthChangeEvent.signedOut:
          state = const AuthUnauthenticated();
        case AuthChangeEvent.tokenRefreshed:
          final session = event.session;
          if (session != null) {
            state = AuthAuthenticated(session);
          }
        case AuthChangeEvent.userUpdated:
          final session = _client.auth.currentSession;
          if (session != null) {
            state = AuthAuthenticated(session);
          }
        case AuthChangeEvent.passwordRecovery:
          // Password recovery - don't change auth state
          break;
        case AuthChangeEvent.mfaChallengeVerified:
          final session = _client.auth.currentSession;
          if (session != null) {
            state = AuthAuthenticated(session);
          }
      }
    });

    // Set initial state based on current session
    final session = _client.auth.currentSession;
    if (session != null) {
      state = AuthAuthenticated(session);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Returns a valid access token from Supabase.
  String? get validAccessToken => _client.auth.currentSession?.accessToken;

  /// Checks if user is currently authenticated.
  bool get isAuthenticated => _client.auth.currentSession != null;

  /// Logs out the user via Supabase.
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}

/// Provider for authentication state.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return AuthNotifier(client);
});