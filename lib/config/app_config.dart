/// Application configuration constants.
class AppConfig {
  AppConfig._();

  // ── Google OAuth (identity only) ──
  /// Google OAuth Client ID (from Google Cloud Console)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // ── MongoDB Atlas App Services ──
  /// TODO: Replace with your actual Atlas App Services App ID
  /// Get this from: MongoDB Atlas → App Services → Your App → Settings → App ID
  static const String atlasAppId = String.fromEnvironment(
    'ATLAS_APP_ID',
    defaultValue: 'YOUR_ATLAS_APP_ID',
  );

  // ── App Info ──
  static const String appName = 'Listd';
  static const String appVersion = '1.0.0';
}