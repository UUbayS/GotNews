import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../screens/news_detail_screen.dart';
import '../main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Timer? _pollTimer;
  static const _channelBreaking = 'gotnews_breaking';
  static const _channelDefault = 'gotnews_channel';

  static const _androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  static const _iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  static Future<void> initialize() async {
    if (_initialized) return;

    const initSettings = InitializationSettings(android: _androidInit, iOS: _iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _onTap(details!.notificationResponse);
    }

    _initialized = true;
  }

  static void startForegroundPolling({Duration interval = const Duration(seconds: 20)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      final token = await ApiClient.storage.read(key: 'accessToken');
      if (token == null) return;
      await checkAndShowNotifications();
    });
  }

  static void stopForegroundPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static void _onTap(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final articleId = data['articleId'] as String?;
      if (articleId == null || articleId.isEmpty) return;
      _openArticle(articleId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification payload parse error: $e');
      }
    }
  }

  static Future<void> _openArticle(String articleId) async {
    final nav = globalNavigatorKey.currentState;
    if (nav == null) return;
    try {
      final item = await NewsService.fetchArticleById(articleId);
      nav.push(MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to open article from notification: $e');
      }
    }
  }

  static Future<void> checkAndShowNotifications() async {
    if (!_initialized) await initialize();

    try {
      final response = await ApiClient.get('/auth/notifications?limit=10');
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final notifications = data['notifications'] as List? ?? [];
      final prefs = await SharedPreferences.getInstance();
      final lastShownId = prefs.getString('last_shown_notification') ?? '';

      for (final n in notifications) {
        if (n['isRead'] == true) continue;
        if (n['id'] == lastShownId) break;

        final type = n['type'] as String? ?? 'info';
        final isBreaking = type == 'breaking';
        final payload = n['articleId'] != null
            ? jsonEncode({'type': type, 'articleId': n['articleId'], 'notificationId': n['id']})
            : jsonEncode({'type': type, 'notificationId': n['id']});

        await _showLocalNotification(
          id: n['id'].hashCode,
          title: n['title'] ?? 'Notification',
          body: n['message'] ?? '',
          isBreaking: isBreaking,
          payload: payload,
        );
      }

      if (notifications.isNotEmpty) {
        await prefs.setString('last_shown_notification', notifications.first['id']);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Notification poll failed: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required bool isBreaking,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      isBreaking ? _channelBreaking : _channelDefault,
      isBreaking ? 'Breaking News' : 'GotNews Notifications',
      channelDescription: isBreaking
          ? 'High-priority breaking news alerts'
          : 'General notifications from GotNews',
      importance: isBreaking ? Importance.max : Importance.high,
      priority: isBreaking ? Priority.max : Priority.high,
      category: isBreaking ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.message,
      icon: '@mipmap/ic_launcher',
      ticker: title,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
