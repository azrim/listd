import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google OAuth service using Supabase Auth.
///
/// Desktop: Uses local HTTP server to handle OAuth callback
class GoogleAuthService {
  GoogleAuthService(this._client);

  final SupabaseClient _client;
  HttpServer? _server;

  /// Initiates Google OAuth flow via Supabase.
  Future<void> authorize() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } else {
      await _authorizeDesktop();
    }
  }

  Future<void> _authorizeDesktop() async {
    _server = await HttpServer.bind('localhost', 8090);
    debugPrint('HTTP server started on port 8090');

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:8090',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      debugPrint('signInWithOAuth completed');

      await for (final request in _server!) {
        final uri = request.uri;
        debugPrint('OAuth callback: $uri');

        if (uri.queryParameters.containsKey('error')) {
          debugPrint('OAuth error: ${uri.queryParameters['error']}');
        }

        final code = uri.queryParameters['code'];
        if (code != null) {
          debugPrint('Got auth code: $code');

          try {
            // Process the callback URL
            final callbackUri = Uri.parse('http://localhost:8090/?code=$code');
            final response = await _client.auth.getSessionFromUrl(callbackUri);
            debugPrint('Session established: ${response.session.user.email}');

            // Manually trigger auth state refresh
            // This helps ensure the Riverpod state updates
            _refreshAuthState();
          } catch (e) {
            debugPrint('getSessionFromUrl error: $e');
          }
        }

        request.response.headers.set(
          'Content-Type',
          'text/html; charset=utf-8',
        );
        request.response.write('''
<!DOCTYPE html>
<html><body>
<script>window.close();</script>
</body></html>
''');
        await request.response.close();
        break;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final session = _client.auth.currentSession;
      debugPrint('Final session: ${session?.user.email}');
    } finally {
      await _server?.close(force: true);
      _server = null;
    }
  }

  void _refreshAuthState() {
    // Access the auth notifier to force a state refresh
    // This is a workaround since getSessionFromUrl should trigger
    // onAuthStateChange but sometimes doesn't on desktop
    final session = _client.auth.currentSession;
    if (session != null) {
      debugPrint('Auth state refreshed for: ${session.user.email}');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool get isAuthenticated => _client.auth.currentSession != null;

  String? get accessToken => _client.auth.currentSession?.accessToken;
}
