import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing OAuth tokens using platform keychain/keystore.
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiresAtKey = 'token_expires_at';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            lOptions: LinuxOptions(),
          );

  /// Gets the stored access token.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Stores the access token.
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Gets the stored refresh token.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Stores the refresh token.
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Gets the token expiration timestamp (milliseconds since epoch).
  Future<int?> getTokenExpiresAt() async {
    final value = await _storage.read(key: _tokenExpiresAtKey);
    return value != null ? int.tryParse(value) : null;
  }

  /// Stores the token expiration timestamp (milliseconds since epoch).
  Future<void> setTokenExpiresAt(int expiresAt) async {
    await _storage.write(key: _tokenExpiresAtKey, value: expiresAt.toString());
  }

  /// Clears all stored tokens.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Checks if tokens are stored.
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null || refreshToken != null;
  }
}
