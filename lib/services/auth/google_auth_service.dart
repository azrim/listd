import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Google OAuth service using Supabase Auth.
///
/// This replaces the manual OAuth2 PKCE flow with Supabase's built-in
/// Google OAuth integration. Supabase handles all token management,
/// refresh, and secure storage automatically.
class GoogleAuthService {
  GoogleAuthService(this._client);

  final SupabaseClient _client;

  /// Initiates Google OAuth flow via Supabase.
  ///
  /// Opens browser for authentication and handles the callback
  /// via deep link. Supabase manages all token operations.
  Future<void> authorize() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.redirectUrl,
      scopes: 'openid email profile',
    );
  }

  /// Signs out the current user via Supabase.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if user is currently authenticated.
  bool get isAuthenticated => _client.auth.currentSession != null;

  /// Get the current access token (managed by Supabase).
  String? get accessToken => _client.auth.currentSession?.accessToken;
}