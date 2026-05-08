import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client_service.dart';

/// Represents the authentication state of the application.
sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final Session session;

  const AuthAuthenticated(this.session);

  bool willExpireWithin(Duration duration) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return expiryTime.difference(DateTime.now()) < duration;
  }
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

/// Notifier for managing authentication state via Supabase.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._client) : super(const AuthLoading()) {
    _init();
  }

  final SupabaseClient _client;

  void _init() {
    // Listen to Supabase auth state changes
    _client.auth.onAuthStateChange.listen((authState) {
      final event = authState.event;
      final session = authState.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          state = session != null
              ? AuthAuthenticated(session)
              : const AuthUnauthenticated();
        case AuthChangeEvent.signedOut:
        // ignore: deprecated_member_use
        case AuthChangeEvent.userDeleted:
          state = const AuthUnauthenticated();
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.mfaChallengeVerified:
          final currentSession = _client.auth.currentSession;
          if (currentSession != null) {
            state = AuthAuthenticated(currentSession);
          }
        case AuthChangeEvent.initialSession:
          if (session != null) {
            state = AuthAuthenticated(session);
          } else {
            state = const AuthUnauthenticated();
          }
        case AuthChangeEvent.passwordRecovery:
          // No auth-state change for password recovery flow.
          break;
      }
    });

    // Set initial state
    final session = _client.auth.currentSession;
    if (session != null) {
      state = AuthAuthenticated(session);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  String? get validAccessToken => _client.auth.currentSession?.accessToken;

  bool get isAuthenticated => _client.auth.currentSession != null;

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
