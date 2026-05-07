import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

/// Google OAuth2 configuration constants.
class GoogleOAuthConfig {
  static const String clientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
  );

  static const String authorizationEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const String revocationEndpoint =
      'https://oauth2.googleapis.com/revoke';

  static const String scopes = 'https://www.googleapis.com/auth/tasks';

  static const String redirectUri = 'http://localhost:8080/callback';

  static const List<String> defaultScopes = [scopes];
}

/// Result of a token refresh operation.
class TokenRefreshResult {
  final String accessToken;
  final int expiresAt; // milliseconds since epoch

  const TokenRefreshResult({
    required this.accessToken,
    required this.expiresAt,
  });
}

/// Service for Google OAuth2 PKCE authentication flow.
class GoogleAuthService {
  final SecureStorageService secureStorage;

  String? _codeVerifier;

  GoogleAuthService({required this.secureStorage});

  /// Generates a random code verifier for PKCE.
  String generateCodeVerifier() {
    final random = Random.secure();
    final codeVerifierBytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );
    final codeVerifier = base64UrlEncode(
      codeVerifierBytes,
    ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
    _codeVerifier = codeVerifier;
    return codeVerifier;
  }

  /// Generates a code challenge from the code verifier using SHA256.
  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(
      digest.bytes,
    ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
    return codeChallenge;
  }

  /// Initiates the OAuth2 authorization flow.
  /// Opens the browser for user authentication, waits for callback,
  /// and exchanges the code for tokens.
  ///
  /// Returns [TokenRefreshResult] on success.
  /// Throws [AuthorizationException] on failure.
  Future<TokenRefreshResult> authorize() async {
    // Generate PKCE verifier and challenge
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);

    // Build authorization URL
    final redirectUri = GoogleOAuthConfig.redirectUri;
    final authEndpoint = GoogleOAuthConfig.authorizationEndpoint;
    final clientId = GoogleOAuthConfig.clientId;
    final scopes = GoogleOAuthConfig.defaultScopes;

    final authUri = Uri.parse(authEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    // Open browser for authorization
    if (kDebugMode) {
      print('Opening browser for authorization: $authUri');
    }

    // On desktop, we use a local server to handle the callback
    final codeCompleter = Completer<String>();

    // Start a local HTTP server to handle the callback
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

    // Listen for the callback
    server.listen((request) async {
      final uri = request.uri;
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        request.response.statusCode = 400;
        request.response.writeln('Error: $error');
        await request.response.close();
        await server.close();
        codeCompleter.completeError(AuthorizationException(error, null));
        return;
      }

      if (code != null) {
        request.response.statusCode = 200;
        request.response.writeln(
          'Authorization successful! You can close this tab.',
        );
        await request.response.close();
        await server.close();
        codeCompleter.complete(code);
        return;
      }

      request.response.statusCode = 400;
      request.response.writeln('No authorization code received');
      await request.response.close();
    });

    // Open browser
    _openBrowser(authUri.toString());

    // Wait for the authorization code
    final code = await codeCompleter.future;

    // Exchange code for tokens
    return _exchangeCodeForTokens(code);
  }

  /// Opens the system browser with the given URL.
  /// Uses Platform.startSocketVin peer on each platform.
  void _openBrowser(String url) {
    // On Linux, use xdg-open
    if (Platform.isLinux) {
      Process.start('xdg-open', [url]);
    } else if (Platform.isMacOS) {
      Process.start('open', [url]);
    } else if (Platform.isWindows) {
      Process.start('start', [url], runInShell: true);
    }
  }

  /// Exchanges an authorization code for tokens.
  Future<TokenRefreshResult> _exchangeCodeForTokens(String code) async {
    final tokenEndpoint = GoogleOAuthConfig.tokenEndpoint;
    final clientId = GoogleOAuthConfig.clientId;
    final redirectUri = GoogleOAuthConfig.redirectUri;
    final codeVerifier = _codeVerifier;

    if (codeVerifier == null) {
      throw StateError('Code verifier not set. Call authorize() first.');
    }

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw AuthorizationException(
        error['error'] ?? 'unknown_error',
        error['error_description'],
      );
    }

    final data = jsonDecode(response.body);
    final accessToken = data['access_token'] as String;
    final expiresIn = data['expires_in'] as int;
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;

    // Store tokens
    await secureStorage.setAccessToken(accessToken);
    if (data['refresh_token'] != null) {
      await secureStorage.setRefreshToken(data['refresh_token'] as String);
    }
    await secureStorage.setTokenExpiresAt(expiresAt);

    // Clear PKCE values
    _codeVerifier = null;

    return TokenRefreshResult(accessToken: accessToken, expiresAt: expiresAt);
  }

  /// Refreshes the access token using the refresh token.
  Future<TokenRefreshResult?> refreshAccessToken(String refreshToken) async {
    final tokenEndpoint = GoogleOAuthConfig.tokenEndpoint;
    final clientId = GoogleOAuthConfig.clientId;

    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Token refresh failed: ${response.body}');
        }
        return null;
      }

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String;
      final expiresIn = data['expires_in'] as int;
      final expiresAt = DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch;

      // Store new access token
      await secureStorage.setAccessToken(accessToken);
      await secureStorage.setTokenExpiresAt(expiresAt);

      return TokenRefreshResult(accessToken: accessToken, expiresAt: expiresAt);
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh error: $e');
      }
      return null;
    }
  }

  /// Revokes the current access token.
  Future<void> revoke() async {
    final accessToken = await secureStorage.getAccessToken();
    if (accessToken == null) return;

    final revocationEndpoint = GoogleOAuthConfig.revocationEndpoint;

    try {
      await http.post(
        Uri.parse(revocationEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'token': accessToken},
      );
    } finally {
      await secureStorage.clearAll();
    }
  }
}

/// Exception thrown when authorization fails.
class AuthorizationException implements Exception {
  final String error;
  final String? description;

  const AuthorizationException(this.error, this.description);

  @override
  String toString() =>
      'AuthorizationException: $error${description != null ? ' - $description' : ''}';
}
