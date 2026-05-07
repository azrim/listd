import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';
import 'google_auth_service.dart';

/// Represents the authentication state of the application.
sealed class AuthState {
  const AuthState();
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated and has valid tokens.
class AuthAuthenticated extends AuthState {
  final String accessToken;
  final int expiresAt;

  const AuthAuthenticated({required this.accessToken, required this.expiresAt});

  /// Check if token will expire within the specified minutes.
  bool willExpireWithin(Duration duration) {
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
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

/// Manages OAuth token storage and refresh logic.
class TokenManager {
  final SecureStorageService _secureStorage;
  final GoogleAuthService _authService;

  TokenManager({
    required SecureStorageService secureStorage,
    required GoogleAuthService authService,
  }) : _secureStorage = secureStorage,
       _authService = authService;

  /// Returns a valid access token, refreshing if necessary.
  /// Returns null if not authenticated or refresh fails.
  Future<String?> getValidAccessToken() async {
    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    final expiresAt = await _secureStorage.getTokenExpiresAt();

    if (accessToken == null || refreshToken == null || expiresAt == null) {
      return null;
    }

    // Auto-refresh if token will expire within 5 minutes
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));

    if (expiryTime.isBefore(fiveMinutesFromNow)) {
      try {
        final newToken = await _authService.refreshAccessToken(refreshToken);
        if (newToken != null) {
          await _secureStorage.setAccessToken(newToken.accessToken);
          await _secureStorage.setTokenExpiresAt(newToken.expiresAt);
          return newToken.accessToken;
        }
      } catch (e) {
        // Refresh failed, tokens are invalid
        await _secureStorage.clearAll();
        return null;
      }
    }

    return accessToken;
  }

  /// Checks if user is currently authenticated.
  Future<bool> isAuthenticated() async {
    final accessToken = await getValidAccessToken();
    return accessToken != null;
  }

  /// Clears all stored tokens (logout).
  Future<void> logout() async {
    await _secureStorage.clearAll();
  }
}

/// Notifier for managing authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  final TokenManager _tokenManager;

  AuthNotifier({required TokenManager tokenManager})
    : _tokenManager = tokenManager,
      super(const AuthLoading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _tokenManager.getValidAccessToken();
      if (token != null) {
        final expiresAt = await _secureStorage.getTokenExpiresAt();
        state = AuthAuthenticated(
          accessToken: token,
          expiresAt: expiresAt ?? DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  SecureStorageService get _secureStorage => _tokenManager._secureStorage;

  /// Refreshes the access token.
  Future<void> refreshToken() async {
    final token = await _tokenManager.getValidAccessToken();
    if (token != null) {
      final expiresAt = await _secureStorage.getTokenExpiresAt();
      state = AuthAuthenticated(
        accessToken: token,
        expiresAt: expiresAt ?? DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Logs out the user.
  Future<void> logout() async {
    await _tokenManager.logout();
    state = const AuthUnauthenticated();
  }

  /// Updates state after successful authentication.
  void setAuthenticated(String accessToken, int expiresAt) {
    state = AuthAuthenticated(accessToken: accessToken, expiresAt: expiresAt);
  }
}

/// Provider for SecureStorageService.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for GoogleAuthService.
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return GoogleAuthService(secureStorage: storage);
});

/// Provider for TokenManager.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final authService = ref.watch(googleAuthServiceProvider);
  return TokenManager(secureStorage: storage, authService: authService);
});

/// Provider for authentication state.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return AuthNotifier(tokenManager: tokenManager);
});
