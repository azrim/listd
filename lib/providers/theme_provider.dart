import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kThemeModeKey = 'listd.themeMode';
const _kAutoSyncKey = 'listd.autoSync';

const _storage = FlutterSecureStorage();

ThemeMode _decodeThemeMode(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _encodeThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// Notifier for theme mode that persists user choice across launches.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final raw = await _storage.read(key: _kThemeModeKey);
      state = _decodeThemeMode(raw);
    } catch (_) {
      // Ignore — fall back to system default.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _kThemeModeKey, value: _encodeThemeMode(mode));
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

/// Provider for theme mode state management.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

/// Notifier for the "auto-sync" toggle in Settings. Persists across launches.
class AutoSyncNotifier extends StateNotifier<bool> {
  AutoSyncNotifier() : super(true) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final raw = await _storage.read(key: _kAutoSyncKey);
      if (raw != null) state = raw == 'true';
    } catch (_) {}
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      await _storage.write(key: _kAutoSyncKey, value: enabled.toString());
    } catch (_) {}
  }
}

final autoSyncProvider = StateNotifierProvider<AutoSyncNotifier, bool>((ref) {
  return AutoSyncNotifier();
});
