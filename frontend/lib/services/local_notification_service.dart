import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    _initialized = true;
  }

  static Future<void> checkAndShowNotifications() async {
    if (!_initialized) await initialize();

    try {
      final response = await ApiClient.get('/auth/notifications?limit=5');
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final notifications = data['notifications'] as List? ?? [];
      final prefs = await SharedPreferences.getInstance();
      final lastShownId = prefs.getString('last_shown_notification') ?? '';

      for (final n in notifications) {
        if (n['isRead'] == true) continue;
        if (n['id'] == lastShownId) break;

        await _showLocalNotification(
          id: n['id'].hashCode,
          title: n['title'] ?? 'Notification',
          body: n['message'] ?? '',
        );
      }

      if (notifications.isNotEmpty) {
        await prefs.setString('last_shown_notification', notifications.first['id']);
      }
    } catch (e) {}
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gotnews_channel',
      'GotNews Notifications',
      channelDescription: 'Notifications from GotNews',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }
}
