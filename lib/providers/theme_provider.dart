import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_density.dart';

const _kThemeModeKey = 'listd.themeMode';
const _kAutoSyncKey = 'listd.autoSync';
const _kAccentColorKey = 'listd.accentColor';
const _kFontScaleKey = 'listd.fontScale';
const _kDensityModeKey = 'listd.densityMode';
const _kBackplateDriftKey = 'listd.backplateDrift';
const _kEmailSummariesKey = 'listd.notifications.emailSummaries';
const _kPushNotificationsKey = 'listd.notifications.pushNotifications';
const _kDueDateRemindersKey = 'listd.notifications.dueDateReminders';
const _kRepeatRemindersKey = 'listd.notifications.repeatReminders';
const _kStarredAlertsKey = 'listd.notifications.starredAlerts';

/// Single SharedPreferences instance shared by every preference notifier.
///
/// `flutter_secure_storage` was previously used for these values, but on
/// Linux it talks to libsecret over D-Bus and adds 100–300ms latency per
/// read/write. None of these values are sensitive, so plain
/// SharedPreferences (a JSON-backed file on Linux) is the right tool.
class _PrefsCache {
  static SharedPreferences? _instance;
  static Future<SharedPreferences>? _initFuture;

  static Future<SharedPreferences> instance() {
    final cached = _instance;
    if (cached != null) return Future.value(cached);
    return _initFuture ??= SharedPreferences.getInstance().then((p) {
      _instance = p;
      return p;
    });
  }
}

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
    final prefs = await _PrefsCache.instance();
    state = _decodeThemeMode(prefs.getString(_kThemeModeKey));
  }

  /// Updates state synchronously, then persists asynchronously.
  /// Callers should NOT await — UI updates happen instantly.
  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(_persist(mode));
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await _PrefsCache.instance();
    await prefs.setString(_kThemeModeKey, _encodeThemeMode(mode));
  }

  void toggleTheme() {
    setThemeMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
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

  /// Default seed color. Mirrors `AppColors.indigo600` so the swatches
  /// in Settings start with the 2027 · Indigo Edition brand color
  /// highlighted.
  static const Color defaultAccent = Color(0xFF4F46E5);

  Future<void> _hydrate() async {
    final prefs = await _PrefsCache.instance();
    final raw = prefs.getInt(_kAccentColorKey);
    if (raw == null) return;
    final stored = Color(raw);
    // Migration: any pre-Indigo value (warm flame `#FF6B35`, the
    // legacy `#FF8A5C` dark-mode flame, etc.) gets clamped to the
    // closest 2027 swatch. The official 5 are indigo / sky / emerald
    // / amber / pink. Anything outside this set resets to indigo so
    // the redesign starts on-brand for users coming from the warm
    // build.
    final isOfficial = kAccentSwatches.any(
      // ignore: deprecated_member_use
      (c) => c.value == stored.value,
    );
    if (isOfficial) {
      state = stored;
    } else {
      state = defaultAccent;
      unawaited(_persist(defaultAccent));
    }
  }

  void setAccent(Color color) {
    state = color;
    unawaited(_persist(color));
  }

  Future<void> _persist(Color color) async {
    final prefs = await _PrefsCache.instance();
    // ignore: deprecated_member_use
    await prefs.setInt(_kAccentColorKey, color.value);
  }
}

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  return AccentColorNotifier();
});

/// Notifier for the global text-scale factor picked in Settings.
/// Range is clamped to a sensible interval (0.8x – 1.4x).
///
/// State updates are synchronous and disk writes are debounced so a
/// fast slider drag doesn't cause repeated writes (which would also
/// queue up extra theme rebuilds).
class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(1.0) {
    _hydrate();
  }

  static const double minScale = 0.8;
  static const double maxScale = 1.4;

  Timer? _persistDebounce;

  Future<void> _hydrate() async {
    final prefs = await _PrefsCache.instance();
    final raw = prefs.getDouble(_kFontScaleKey);
    if (raw != null) state = raw.clamp(minScale, maxScale);
  }

  void setScale(double scale) {
    final clamped = scale.clamp(minScale, maxScale);
    if (clamped == state) return;
    state = clamped;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_persist(clamped));
    });
  }

  Future<void> _persist(double scale) async {
    final prefs = await _PrefsCache.instance();
    await prefs.setDouble(_kFontScaleKey, scale);
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    super.dispose();
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
    final prefs = await _PrefsCache.instance();
    state = NotificationPrefs(
      emailSummaries: prefs.getBool(_kEmailSummariesKey) ?? true,
      pushNotifications: prefs.getBool(_kPushNotificationsKey) ?? false,
      dueDateReminders: prefs.getBool(_kDueDateRemindersKey) ?? true,
      repeatReminders: prefs.getBool(_kRepeatRemindersKey) ?? true,
      starredAlerts: prefs.getBool(_kStarredAlertsKey) ?? false,
    );
  }

  void setEmailSummaries(bool value) {
    state = state.copyWith(emailSummaries: value);
    unawaited(_persist(_kEmailSummariesKey, value));
  }

  void setPushNotifications(bool value) {
    state = state.copyWith(pushNotifications: value);
    unawaited(_persist(_kPushNotificationsKey, value));
  }

  void setDueDateReminders(bool value) {
    state = state.copyWith(dueDateReminders: value);
    unawaited(_persist(_kDueDateRemindersKey, value));
  }

  void setRepeatReminders(bool value) {
    state = state.copyWith(repeatReminders: value);
    unawaited(_persist(_kRepeatRemindersKey, value));
  }

  void setStarredAlerts(bool value) {
    state = state.copyWith(starredAlerts: value);
    unawaited(_persist(_kStarredAlertsKey, value));
  }

  Future<void> _persist(String key, bool value) async {
    final prefs = await _PrefsCache.instance();
    await prefs.setBool(key, value);
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
    final prefs = await _PrefsCache.instance();
    final raw = prefs.getBool(_kAutoSyncKey);
    if (raw != null) state = raw;
  }

  void setEnabled(bool enabled) {
    state = enabled;
    unawaited(_persist(enabled));
  }

  Future<void> _persist(bool enabled) async {
    final prefs = await _PrefsCache.instance();
    await prefs.setBool(_kAutoSyncKey, enabled);
  }
}

final autoSyncProvider = StateNotifierProvider<AutoSyncNotifier, bool>((ref) {
  return AutoSyncNotifier();
});

/// The list of accent colors users can pick from in Settings.
///
/// Indigo is the system default. Alternates apply only to selection
/// and primary buttons; functional dots stay emerald / amber / red.
const List<Color> kAccentSwatches = <Color>[
  AccentColorNotifier.defaultAccent, // indigo-600
  Color(0xFF0EA5E9), // sky-500 (cobalt)
  Color(0xFF10B981), // emerald-500
  Color(0xFFF59E0B), // amber-500
  Color(0xFFEC4899), // pink-500 (fuchsia)
];

/// Notifier for the active [DensityMode]. Cozy by default. Persists
/// across launches. Reads/writes use the same `_PrefsCache` as the
/// other preference notifiers in this file.
class DensityModeNotifier extends StateNotifier<DensityMode> {
  DensityModeNotifier() : super(DensityMode.cozy) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await _PrefsCache.instance();
    state = DensityMode.fromKey(prefs.getString(_kDensityModeKey));
  }

  void setMode(DensityMode mode) {
    if (mode == state) return;
    state = mode;
    unawaited(_persist(mode));
  }

  void toggle() {
    setMode(state == DensityMode.cozy ? DensityMode.compact : DensityMode.cozy);
  }

  Future<void> _persist(DensityMode mode) async {
    final prefs = await _PrefsCache.instance();
    await prefs.setString(_kDensityModeKey, mode.key);
  }
}

final densityModeProvider =
    StateNotifierProvider<DensityModeNotifier, DensityMode>(
      (ref) => DensityModeNotifier(),
    );

/// Notifier for whether the ambient backplate's time-of-day color
/// drift is enabled. Defaults to `true` so existing installs see the
/// drift unless they explicitly opt out.
class BackplateDriftNotifier extends StateNotifier<bool> {
  BackplateDriftNotifier() : super(true) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await _PrefsCache.instance();
    final raw = prefs.getBool(_kBackplateDriftKey);
    if (raw != null) state = raw;
  }

  void setEnabled(bool enabled) {
    if (enabled == state) return;
    state = enabled;
    unawaited(_persist(enabled));
  }

  Future<void> _persist(bool enabled) async {
    final prefs = await _PrefsCache.instance();
    await prefs.setBool(_kBackplateDriftKey, enabled);
  }
}

final backplateDriftProvider =
    StateNotifierProvider<BackplateDriftNotifier, bool>(
      (ref) => BackplateDriftNotifier(),
    );
