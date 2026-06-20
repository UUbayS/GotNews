import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isSyncing = false;
  bool _isTestingNotification = false;
  String? _testLastResult;
  Map<String, dynamic>? _stats;
  String? _targetUserId;
  String? _targetUserLabel;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await AdminService.fetchStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Silently fail for stats
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Menyinkronkan berita terbaru...'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    try {
      await AdminService.triggerSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sinkronisasi berhasil!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sinkronisasi gagal: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _sendTestNotification(String type) async {
    setState(() {
      _isTestingNotification = true;
      _testLastResult = null;
    });
    try {
      final result = await AdminService.sendTestNotification(
        type: type,
        userId: _targetUserId,
      );
      if (mounted) {
        setState(() {
          _testLastResult = result['message']?.toString() ?? 'Sent';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_testLastResult!),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testLastResult = 'Gagal: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notifikasi gagal: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingNotification = false);
    }
  }

  Future<void> _pickTargetUser() async {
    final adminEmail = context.read<AuthService>().currentUser?.email;
    List<User> users;
    try {
      users = await AdminService.fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar user: $e')),
        );
      }
      return;
    }

    if (!mounted) return;
    final picked = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih User Target',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(sheetContext).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notifikasi test akan dikirim ke user ini',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                    ),
                    title: const Text('Admin sendiri'),
                    subtitle: Text(adminEmail ?? ''),
                    onTap: () => Navigator.pop(sheetContext, null),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = users[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: u.isBanned ? Colors.red.shade100 : Colors.blue.shade100,
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: u.isBanned ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(u.name),
                          subtitle: Text('${u.email}${u.isBanned ? " • BANNED" : ""}'),
                          trailing: u.role == 'admin'
                              ? const Icon(Icons.admin_panel_settings, size: 16, color: Colors.amber)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, u),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _targetUserId = picked.id;
        _targetUserLabel = '${picked.name} (${picked.email})';
      });
    } else if (mounted) {
      setState(() {
        _targetUserId = null;
        _targetUserLabel = 'Admin sendiri';
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari akun admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.settings, color: Colors.grey.shade600, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color ?? const Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Info
            Text(
              'Akun Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color ?? Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (user?.name != null && user!.name.isNotEmpty) ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.textTheme.bodyLarge?.color ?? Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sync Settings
            Text(
              'Sinkronisasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color ?? Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sync, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Sinkronkan Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Ambil berita terbaru dari semua sumber aktif',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _isSyncing ? null : _triggerSync,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rss_feed, color: Color(0xFF10B981), size: 20),
                    ),
                    title: Text(
                      'Sumber Aktif',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      '${_stats?['activeSources'] ?? 0} sumber sedang aktif',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Test Notifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color ?? Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_pin, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'User Target',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      _targetUserLabel ?? 'Admin sendiri',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _pickTargetUser,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flash_on, color: Colors.red, size: 20),
                    ),
                    title: const Text(
                      'Test Breaking News',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Kirim push breaking ke user target',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: _isTestingNotification
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _isTestingNotification ? null : () => _sendTestNotification('breaking'),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bookmark, color: Colors.amber, size: 20),
                    ),
                    title: const Text(
                      'Test Bookmark Reminder',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Kirim reminder ke akun admin ini',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: _isTestingNotification
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _isTestingNotification ? null : () => _sendTestNotification('reminder'),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.run_circle, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Jalankan Cron Bookmark Reminder',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Trigger job harian sekarang (cek unread bookmark >24 jam)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: _isTestingNotification
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _isTestingNotification ? null : () => _sendTestNotification('run-job'),
                  ),
                  if (_testLastResult != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testLastResult!,
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Info
            Text(
              'Sistem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color ?? Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    ),
                    title: const Text(
                      'Versi Aplikasi',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      'GotNews v1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout, color: Colors.red.shade400, size: 20),
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.red.shade600),
                    ),
                    subtitle: Text(
                      'Keluar dari akun admin',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
