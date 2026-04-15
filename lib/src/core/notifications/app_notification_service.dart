import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  static const int _dailyReminderId = 4101;
  static const String _dailyChannelId = 'daily-speaking-reminders';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dailyChannelId,
        'Daily Speaking Reminders',
        description: 'Daily reminders for speaking tasks and routines.',
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();

    var granted = true;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidResult = await androidPlugin?.requestNotificationsPermission();
    if (androidResult != null) {
      granted = granted && androidResult;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosResult = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosResult != null) {
      granted = granted && iosResult;
    }

    return granted;
  }

  Future<void> scheduleDailyReminder({
    required String reminderWindow,
    required bool isTurkish,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final granted = await requestPermissions();
    if (!granted) return;

    await _notifications.cancel(_dailyReminderId);

    final hour = switch (reminderWindow) {
      'morning' => 9,
      'afternoon' => 14,
      _ => 19,
    };

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _dailyReminderId,
      isTurkish
          ? 'Gunluk speaking gorevin hazir'
          : 'Your daily speaking task is ready',
      isTurkish
          ? 'Mini paketini ac, streaki koru ve uygun hocayi kacirma.'
          : 'Open your mini pack, keep the streak alive, and do not miss the right tutor.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          'Daily Speaking Reminders',
          channelDescription:
              'Daily reminders for speaking tasks and routines.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await initialize();
    await _notifications.cancel(_dailyReminderId);
  }
}
