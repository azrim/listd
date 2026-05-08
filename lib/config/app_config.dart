/// Application configuration constants.
class AppConfig {
  AppConfig._();

  // ── Supabase ──
  /// Get this from: Supabase Dashboard → Settings → API → Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vkigvohwlgvhudlwhlyh.supabase.co',
  );

  /// Get this from: Supabase Dashboard → Settings → API → anon public key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZraWd2b2h3bGd2aHVkbHdobHloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNzM4NzQsImV4cCI6MjA5Mzc0OTg3NH0.jll8L5D-KB3zc1U7k23OVUDI2_wCM3loSdncFBi-dJM';

  // ── Deep Link ──
  /// Deep link URL for OAuth callback (must match Supabase redirect URL)
  static const String redirectUrl = 'io.listd://login-callback';

  // ── Google OAuth (identity only) ──
  /// Google OAuth Client ID (from Google Cloud Console)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '335779516211-obq7kliv5p54djs062p6b7hjohci20cm.apps.googleusercontent.com',
  );

  // ── App Info ──
  static const String appName = 'Listd';
  static const String appVersion = '1.0.0';
}
