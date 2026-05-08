/// Application configuration constants.
///
/// Sensitive values (Supabase URL, anon key, Google OAuth client ID) are
/// supplied at build time via `--dart-define` so credentials never live in
/// the source tree. See `README.md` for the full run command.
class AppConfig {
  AppConfig._();

  // ── Supabase ──
  /// Get this from: Supabase Dashboard → Settings → API → Project URL
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Get this from: Supabase Dashboard → Settings → API → anon public key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // ── Deep Link ──
  /// Deep link URL for OAuth callback (must match Supabase redirect URL).
  static const String redirectUrl = 'io.listd://login-callback';

  // ── Google OAuth (identity only) ──
  /// Google OAuth Client ID (from Google Cloud Console).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  // ── App Info ──
  static const String appName = 'Listd';
  static const String appVersion = '1.0.0';

  /// Validates that all required `--dart-define` values are present.
  ///
  /// Throws [StateError] with a human-readable message listing the missing
  /// variables. Call from `main()` before any service touches these values
  /// so the app fails fast instead of crashing inside the Supabase client.
  static void assertConfigured() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
      if (googleClientId.isEmpty) 'GOOGLE_CLIENT_ID',
    ];
    if (missing.isEmpty) return;
    throw StateError(
      'Missing required --dart-define values: ${missing.join(', ')}. '
      'See README.md for the full run command.',
    );
  }
}
