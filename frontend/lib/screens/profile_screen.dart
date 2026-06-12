import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'edit_profile_screen.dart';
import 'topics_screen.dart';
import 'notifications_screen.dart';
import 'reading_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showFullPhoto(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return;
    final fullUrl = ApiClient.getAvatarUrl(avatarUrl);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fullUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, url, error) => Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.error, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.public, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'GotNews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                    ? NetworkImage(ApiClient.getAvatarUrl(user.avatarUrl))
                    : const NetworkImage('https://via.placeholder.com/150'),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user?.name ?? 'Unknown',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
            _buildMenuItem(
              context: context,
              title: 'Edit Profile',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              },
            ),
            _buildMenuItem(
              context: context,
              title: 'Topics',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicsScreen()));
              },
            ),
            _buildMenuItem(
              context: context,
              title: 'Reading History',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()));
              },
            ),
            _buildMenuItem(
              context: context,
              title: 'Notifications',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
            ),
            const SizedBox(height: 40),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Log Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              onTap: () {
                context.read<AuthService>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required BuildContext context, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      ),
      trailing: Icon(Icons.chevron_right, color: textColor),
      onTap: onTap,
    );
  }
}
