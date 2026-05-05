import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../network/api_client.dart';
import '../storage/secure_storage.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AppNotificationService.instance.initialize();
}

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  static const int _dailyReminderId = 4101;
  static const int _behavioralBaseId = 5200;
  static const String _dailyChannelId = 'daily-speaking-reminders';
  static const String _serverPushTokenKey = 'server_push_fcm_token_v1';
  static const String _behavioralCooldownsKey = 'behavioral_push_cooldowns_v1';
  static const String _behavioralDailyCountKey =
      'behavioral_push_daily_count_v1';
  static const String _pendingRouteKey = 'pending_notification_route_v1';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _firebaseReady = false;
  bool _tokenRefreshBound = false;

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
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundTap,
    );
    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.trim().isNotEmpty) {
      await _storeRouteFromPayload(launchPayload);
    }

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

    await _initializeFirebaseMessaging();
    _initialized = true;
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_firebaseReady || kIsWeb) return;

    try {
      if (Firebase.apps.isEmpty) {
        final options = _firebaseOptionsForCurrentPlatform();
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          await Firebase.initializeApp();
        }
      }

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_showForegroundRemoteMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_storeRouteFromRemoteMessage);

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _storeRouteFromRemoteMessage(initialMessage);
      }

      if (!_tokenRefreshBound) {
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          await _registerTokenWithServer(token);
        });
        _tokenRefreshBound = true;
      }

      _firebaseReady = true;
    } catch (error, stackTrace) {
      // Firebase config is optional for local/web smoke tests. Real push becomes
      // active after Firebase app credentials are supplied in release builds.
      debugPrint('Firebase messaging init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _firebaseReady = false;
    }
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

  Future<void> syncServerPushToken({
    String reminderWindow = 'evening',
    bool remindersEnabled = true,
  }) async {
    if (kIsWeb) return;
    await initialize();
    if (!_firebaseReady) return;

    final granted = await requestPermissions();
    if (!granted) return;

    try {
      final token = await _resolveMessagingToken();
      if (token == null || token.trim().isEmpty) return;
      await _registerTokenWithServer(
        token,
        reminderWindow: reminderWindow,
        remindersEnabled: remindersEnabled,
      );
    } catch (error, stackTrace) {
      debugPrint('FCM token sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<String?> _resolveMessagingToken() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.trim().isNotEmpty) {
          return token;
        }
      } catch (error) {
        debugPrint('FCM getToken attempt ${attempt + 1} failed: $error');
      }
      await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
    }

    return null;
  }

  Future<void> unregisterServerPushToken() async {
    if (kIsWeb) return;
    final token = await SecureStorage.getValue(_serverPushTokenKey);
    if (token == null || token.trim().isEmpty) return;

    try {
      await ApiClient.dio.delete('/push/devices', data: {'token': token});
      await SecureStorage.deleteValue(_serverPushTokenKey);
    } on DioException {
      // Logout must not fail because a token cleanup request failed.
    } catch (error, stackTrace) {
      debugPrint('FCM token registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
          ? 'Günlük speaking görevin hazır'
          : 'Your daily speaking task is ready',
      isTurkish
          ? 'Mini paketini aç, streakı koru ve uygun hocayı kaçırma.'
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

  Future<void> triggerBehavioralPush({
    required String triggerId,
    required String titleTr,
    required String bodyTr,
    required String titleEn,
    required String bodyEn,
    required bool isTurkish,
    Duration cooldown = const Duration(hours: 24),
    int quietHoursStart = 22,
    int quietHoursEnd = 9,
    int maxPerDay = 3,
    String? route,
  }) async {
    if (kIsWeb) return;
    await initialize();
    final granted = await requestPermissions();
    if (!granted) return;
    final now = DateTime.now();
    final hour = now.hour;
    if (quietHoursStart > quietHoursEnd) {
      if (hour >= quietHoursStart || hour < quietHoursEnd) return;
    } else {
      if (hour >= quietHoursStart && hour < quietHoursEnd) return;
    }
    final sentToday = await _loadDailySentCount(now);
    if (sentToday >= maxPerDay) return;
    final cooldowns = await _loadCooldowns();
    final nextAllowed = cooldowns[triggerId];
    if (nextAllowed != null) {
      final nextTime = DateTime.tryParse(nextAllowed);
      if (nextTime != null && now.isBefore(nextTime)) return;
    }
    cooldowns[triggerId] = now.add(cooldown).toIso8601String();
    await SecureStorage.setValue(
        _behavioralCooldownsKey, jsonEncode(cooldowns));
    final id = _behavioralBaseId + (triggerId.hashCode.abs() % 500);
    await _notifications.show(
      id,
      isTurkish ? titleTr : titleEn,
      isTurkish ? bodyTr : bodyEn,
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
      payload: jsonEncode({'route': route ?? '/start-speaking'}),
    );
    await _saveDailySentCount(now, sentToday + 1);
  }

  Future<String?> consumePendingRoute() async {
    final route = await SecureStorage.getValue(_pendingRouteKey);
    await SecureStorage.deleteValue(_pendingRouteKey);
    final value = (route ?? '').trim();
    return value.isEmpty ? null : value;
  }

  Future<Map<String, String>> _loadCooldowns() async {
    final raw = await SecureStorage.getValue(_behavioralCooldownsKey);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  Future<int> _loadDailySentCount(DateTime now) async {
    final key = '${now.year}-${now.month}-${now.day}';
    final raw = await SecureStorage.getValue(_behavioralDailyCountKey);
    if (raw == null || raw.trim().isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return int.tryParse('${decoded[key] ?? 0}') ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _saveDailySentCount(DateTime now, int value) async {
    final key = '${now.year}-${now.month}-${now.day}';
    final raw = await SecureStorage.getValue(_behavioralDailyCountKey);
    Map<String, dynamic> map = <String, dynamic>{};
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          map = decoded;
        }
      } catch (_) {}
    }
    map[key] = value;
    await SecureStorage.setValue(_behavioralDailyCountKey, jsonEncode(map));
  }

  Future<void> _storeRouteFromPayload(String payload) async {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final route = (decoded['route'] ?? '').toString().trim();
        if (route.isNotEmpty) {
          await SecureStorage.setValue(_pendingRouteKey, route);
        }
      }
    } catch (_) {}
  }

  Future<void> _registerTokenWithServer(
    String token, {
    String reminderWindow = 'evening',
    bool remindersEnabled = true,
  }) async {
    final bearer = await SecureStorage.getToken();
    if (bearer == null || bearer.trim().isEmpty) return;

    try {
      await ApiClient.dio.post('/push/devices/register', data: {
        'token': token,
        'platform': _platformName(),
        'timezone': tz.local.name,
        'locale': await SecureStorage.getLanguageCode() ?? 'tr',
        'reminder_window': reminderWindow,
        'reminders_enabled': remindersEnabled,
      });
      await SecureStorage.setValue(_serverPushTokenKey, token);
    } catch (_) {}
  }

  Future<void> _showForegroundRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if ((title ?? '').trim().isEmpty && (body ?? '').trim().isEmpty) return;

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title ?? 'LinguFranca',
      body ?? '',
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
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _storeRouteFromRemoteMessage(RemoteMessage message) async {
    final route = (message.data['route'] ?? '').toString().trim();
    if (route.isNotEmpty) {
      await SecureStorage.setValue(_pendingRouteKey, route);
    }
  }

  String _platformName() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'unknown',
    };
  }

  FirebaseOptions? _firebaseOptionsForCurrentPlatform() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
    const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
    const iosBundleId = String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.lingufranca.app',
    );

    if (apiKey.isEmpty || projectId.isEmpty || senderId.isEmpty) {
      return null;
    }

    final appId =
        defaultTargetPlatform == TargetPlatform.iOS ? iosAppId : androidAppId;
    if (appId.isEmpty) return null;

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      iosBundleId:
          defaultTargetPlatform == TargetPlatform.iOS ? iosBundleId : null,
    );
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    final payload = (response.payload ?? '').trim();
    if (payload.isEmpty) return;
    await _storeRouteFromPayload(payload);
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundTap(NotificationResponse response) {
    // Route persistence for background taps is handled on next initialize().
  }
}
