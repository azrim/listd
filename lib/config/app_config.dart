/// Application configuration constants.
class AppConfig {
  AppConfig._();

  // ── Supabase ──
  /// TODO: Replace with your Supabase project URL
  /// Get this from: Supabase Dashboard → Settings → API → Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  /// TODO: Replace with your Supabase anon key
  /// Get this from: Supabase Dashboard → Settings → API → anon public key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  // ── Deep Link ──
  /// Deep link URL for OAuth callback (must match Supabase redirect URL)
  static const String redirectUrl = 'io.listd://login-callback';

  // ── Google OAuth (identity only) ──
  /// Google OAuth Client ID (from Google Cloud Console)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // ── App Info ──
  static const String appName = 'Listd';
  static const String appVersion = '1.0.0';
}