import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kThemeModeKey = 'listd.themeMode';
const _kAutoSyncKey = 'listd.autoSync';
const _kAccentColorKey = 'listd.accentColor';
const _kFontScaleKey = 'listd.fontScale';
const _kEmailSummariesKey = 'listd.notifications.emailSummaries';
const _kPushNotificationsKey = 'listd.notifications.pushNotifications';
const _kDueDateRemindersKey = 'listd.notifications.dueDateReminders';
const _kRepeatRemindersKey = 'listd.notifications.repeatReminders';
const _kStarredAlertsKey = 'listd.notifications.starredAlerts';

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

/// Notifier for the accent color picked in Settings → Appearance.
/// Persists across launches and is read by the root [MaterialApp] when
/// building [ColorScheme.fromSeed].
class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(defaultAccent) {
    _hydrate();
  }

  /// Default seed color. Mirrors `AppColors.primary` so the swatches in
  /// Settings start with the brand color highlighted.
  static const Color defaultAccent = Color(0xFF5C6BC0);

  Future<void> _hydrate() async {
    try {
      final raw = await _storage.read(key: _kAccentColorKey);
      if (raw != null) {
        final parsed = int.tryParse(raw);
        if (parsed != null) state = Color(parsed);
      }
    } catch (_) {}
  }

  Future<void> setAccent(Color color) async {
    state = color;
    try {
      await _storage.write(
        key: _kAccentColorKey,
        // ignore: deprecated_member_use
        value: color.value.toString(),
      );
    } catch (_) {}
  }
}

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  return AccentColorNotifier();
});

/// Notifier for the global text-scale factor picked in Settings.
/// Range is clamped to a sensible interval (0.8x – 1.4x).
class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(1.0) {
    _hydrate();
  }

  static const double minScale = 0.8;
  static const double maxScale = 1.4;

  Future<void> _hydrate() async {
    try {
      final raw = await _storage.read(key: _kFontScaleKey);
      if (raw != null) {
        final parsed = double.tryParse(raw);
        if (parsed != null) {
          state = parsed.clamp(minScale, maxScale);
        }
      }
    } catch (_) {}
  }

  Future<void> setScale(double scale) async {
    state = scale.clamp(minScale, maxScale);
    try {
      await _storage.write(key: _kFontScaleKey, value: state.toString());
    } catch (_) {}
  }
}

final fontScaleProvider = StateNotifierProvider<FontScaleNotifier, double>((
  ref,
) {
  return FontScaleNotifier();
});

/// Persisted notification preferences.
class NotificationPrefs {
  const NotificationPrefs({
    this.emailSummaries = true,
    this.pushNotifications = false,
    this.dueDateReminders = true,
    this.repeatReminders = true,
    this.starredAlerts = false,
  });

  final bool emailSummaries;
  final bool pushNotifications;
  final bool dueDateReminders;
  final bool repeatReminders;
  final bool starredAlerts;

  NotificationPrefs copyWith({
    bool? emailSummaries,
    bool? pushNotifications,
    bool? dueDateReminders,
    bool? repeatReminders,
    bool? starredAlerts,
  }) {
    return NotificationPrefs(
      emailSummaries: emailSummaries ?? this.emailSummaries,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      dueDateReminders: dueDateReminders ?? this.dueDateReminders,
      repeatReminders: repeatReminders ?? this.repeatReminders,
      starredAlerts: starredAlerts ?? this.starredAlerts,
    );
  }
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs()) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final email = await _storage.read(key: _kEmailSummariesKey);
      final push = await _storage.read(key: _kPushNotificationsKey);
      final due = await _storage.read(key: _kDueDateRemindersKey);
      final repeat = await _storage.read(key: _kRepeatRemindersKey);
      final starred = await _storage.read(key: _kStarredAlertsKey);
      state = NotificationPrefs(
        emailSummaries: email == null ? true : email == 'true',
        pushNotifications: push == 'true',
        dueDateReminders: due == null ? true : due == 'true',
        repeatReminders: repeat == null ? true : repeat == 'true',
        starredAlerts: starred == 'true',
      );
    } catch (_) {}
  }

  Future<void> setEmailSummaries(bool value) async {
    state = state.copyWith(emailSummaries: value);
    await _persist(_kEmailSummariesKey, value);
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    await _persist(_kPushNotificationsKey, value);
  }

  Future<void> setDueDateReminders(bool value) async {
    state = state.copyWith(dueDateReminders: value);
    await _persist(_kDueDateRemindersKey, value);
  }

  Future<void> setRepeatReminders(bool value) async {
    state = state.copyWith(repeatReminders: value);
    await _persist(_kRepeatRemindersKey, value);
  }

  Future<void> setStarredAlerts(bool value) async {
    state = state.copyWith(starredAlerts: value);
    await _persist(_kStarredAlertsKey, value);
  }

  Future<void> _persist(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (_) {}
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>((ref) {
      return NotificationPrefsNotifier();
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

/// The list of accent colors users can pick from in Settings.
const List<Color> kAccentSwatches = <Color>[
  AccentColorNotifier.defaultAccent,
  Color(0xFF38BDF8),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
];
