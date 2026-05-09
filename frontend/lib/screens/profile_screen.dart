import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.public, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'GotNews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: (user?.avatarUrl != null)
                    ? NetworkImage(user!.avatarUrl!)
                    : const NetworkImage('https://via.placeholder.com/150'),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name & Email
            Center(
              child: Text(
                user?.name ?? 'Unknown',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
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

            // Menu Items
            _buildMenuItem(
              title: 'Edit Profile',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              },
            ),
            _buildMenuItem(
              title: 'Topics',
              onTap: () {},
            ),
            _buildMenuItem(
              title: 'Notifications',
              onTap: () {},
            ),
            const SizedBox(height: 40),

            // Logout
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Log Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              onTap: () {
                context.read<AuthService>().logout();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black),
      onTap: onTap,
    );
  }
}
