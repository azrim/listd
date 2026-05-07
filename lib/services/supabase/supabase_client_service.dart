import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Service for initializing and accessing Supabase client.
class SupabaseClientService {
  SupabaseClientService._();

  static SupabaseClient? _client;

  /// Initialize Supabase. Call this before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://vkigvohwlgvhudlwhlyh.supabase.co',
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Returns the Supabase client instance.
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase not initialized. Call SupabaseClientService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized.
  static bool get isInitialized => _client != null;
}

/// Riverpod provider for SupabaseClient.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientService.client;
});

/// Provider for the current authenticated user.
final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

/// Provider for the current session.
final currentSessionProvider = Provider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentSession;
});
