import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/task.dart';

/// Wraps `flutter_local_notifications` with a Riverpod-friendly facade.
///
/// On Linux the plugin uses libnotify; on macOS / Windows the platform
/// notification surfaces. The service is **lazy** — it only initialises
/// the underlying plugin on first use so cold-start cost is paid by the
/// user who actually needs reminders, not by the auth screen.
class ReminderService {
  ReminderService();

  static const _channelId = 'listd_reminders';
  static const _channelName = 'Task reminders';
  static const _channelDescription = 'Listd task reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');
    const macosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      linux: linuxInit,
      macOS: macosInit,
    );
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    }
    if (Platform.isMacOS || Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    _initialized = true;
  }

  /// Schedules a notification for [task]. Existing reminder for this task
  /// id is cancelled first so an updated reminder time replaces the old
  /// one. No-ops if [task] has no reminder, or the reminder is in the
  /// past, or the task is already completed.
  Future<void> schedule(Task task) async {
    final reminder = task.reminder;
    final id = _idFor(task.id);
    if (reminder == null || task.isCompleted) {
      await cancel(task.id);
      return;
    }
    final now = DateTime.now();
    if (!reminder.isAfter(now)) {
      // Don't schedule reminders that are already past — but DO clear
      // any previously-scheduled notification for the same task.
      await cancel(task.id);
      return;
    }

    try {
      await _ensureInit();
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const linuxDetails = LinuxNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        linux: linuxDetails,
        macOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id,
        task.title.isEmpty ? 'Reminder' : task.title,
        task.notes.isEmpty ? null : task.notes,
        tz.TZDateTime.from(reminder, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ReminderService.schedule(${task.id}) failed: $e');
      }
    }
  }

  /// Cancels the notification (if any) bound to [taskId].
  Future<void> cancel(String taskId) async {
    try {
      await _ensureInit();
      await _plugin.cancel(_idFor(taskId));
    } catch (_) {
      // Cancel is best-effort.
    }
  }

  /// Maps a task id (UUID string) to a deterministic 32-bit integer that
  /// the notifications plugin requires. We just hash the string into the
  /// positive int range — collisions are astronomically unlikely with the
  /// number of reminders a single user will ever have outstanding.
  int _idFor(String taskId) => taskId.hashCode & 0x7FFFFFFF; // strip sign bit
}

/// Single shared instance of [ReminderService].
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});
