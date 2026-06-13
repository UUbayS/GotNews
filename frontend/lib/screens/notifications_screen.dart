import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/api_client.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/auth/notifications');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _notifications = data['notifications'] ?? [];
          _unreadCount = data['unreadCount'] ?? 0;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      // ignore
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiClient.put('/auth/notifications/$id/read');
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1 && !_notifications[index]['isRead']) {
          _notifications[index]['isRead'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiClient.put('/auth/notifications/read-all');
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
        _unreadCount = 0;
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Read All',
                style: const TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? EmptyState.noNotifications()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] ?? false;
                      return Container(
                        color: isRead
                            ? Colors.transparent
                            : theme.colorScheme.primary.withValues(alpha: 0.03),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey.withValues(alpha: 0.15)
                                : theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color: isRead
                                  ? Colors.grey
                                  : theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            notification['message'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notification['id']);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'bookmark':
        return Icons.bookmark;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
