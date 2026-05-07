import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google OAuth service using Supabase Auth.
/// 
/// Works on all platforms: web, mobile, and desktop.
class GoogleAuthService {
  GoogleAuthService(this._client);

  final SupabaseClient _client;

  /// Initiates Google OAuth flow via Supabase.
  /// 
  /// For web: Supabase handles redirect in URL params.
  /// For desktop: Supabase opens browser and handles callback internally.
  Future<void> authorize() async {
    developer.log(
      'GoogleAuthService.authorize() called for ${defaultTargetPlatform.name}',
      name: 'GoogleAuthService',
    );

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Don't set redirectTo - let Supabase handle it
      // For web: uses URL params
      // For desktop: uses platform-specific callback handling
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool get isAuthenticated => _client.auth.currentSession != null;

  String? get accessToken => _client.auth.currentSession?.accessToken;
}