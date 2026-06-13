import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/admin_service.dart';

class AdminSourcesScreen extends StatefulWidget {
  const AdminSourcesScreen({super.key});

  @override
  State<AdminSourcesScreen> createState() => _AdminSourcesScreenState();
}

class _AdminSourcesScreenState extends State<AdminSourcesScreen> {
  List<Map<String, dynamic>> _sources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSources();
  }

  Future<void> _fetchSources() async {
    setState(() => _isLoading = true);
    try {
      final sources = await AdminService.fetchSources();
      setState(() {
        _sources = sources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat sumber berita: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleSourceStatus(String id, bool currentStatus) async {
    try {
      await AdminService.editSource(id, isActive: !currentStatus);
      _fetchSources();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal toggle status: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteSource(String id) async {
    try {
      await AdminService.deleteSource(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sumber berhasil dihapus'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchSources();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus sumber: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddSourceDialog() {
    final nameController = TextEditingController();
    final sourceIdController = TextEditingController();
    String selectedLang = 'en';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Sumber', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Sumber',
                    hintText: 'e.g. Detik News',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sourceIdController,
                  decoration: InputDecoration(
                    labelText: 'Source ID',
                    hintText: 'e.g. detik',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedLang,
                  decoration: InputDecoration(
                    labelText: 'Bahasa',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English (en)')),
                    DropdownMenuItem(value: 'id', child: Text('Indonesian (id)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedLang = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final sourceId = sourceIdController.text.trim();
                if (name.isEmpty || sourceId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await AdminService.addSource(
                    name: name,
                    sourceId: sourceId,
                    language: selectedLang,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sumber berhasil ditambahkan'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  _fetchSources();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal tambah sumber: $e'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSourceDialog(Map<String, dynamic> source) {
    final nameController = TextEditingController(text: source['name']);
    String selectedLang = (source['language'] as String?) ?? 'en';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Sumber', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Sumber',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedLang,
                  decoration: InputDecoration(
                    labelText: 'Bahasa',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English (en)')),
                    DropdownMenuItem(value: 'id', child: Text('Indonesian (id)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedLang = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama harus diisi')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await AdminService.editSource(
                    source['id'],
                    name: name,
                    language: selectedLang,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sumber berhasil diupdate'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  _fetchSources();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal update sumber: $e'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Belum pernah';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rss_feed, color: Color(0xFF8B5CF6), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Kelola Sumber',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color ?? const Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.54) ?? Colors.black54),
            onPressed: _fetchSources,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSourceDialog,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
      body: _isLoading
          ? _buildShimmer()
          : _sources.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchSources,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _sources.length,
                    itemBuilder: (context, index) {
                      final s = _sources[index];
                      final bool active = s['isActive'] ?? true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).dividerColor),
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
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : Theme.of(context).dividerColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.rss_feed,
                                color: active ? const Color(0xFF10B981) : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ((s['language'] as String?) ?? 'en').toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${s['sourceId']}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Terakhir ambil: ${_formatDate(s['lastFetchedAt'])}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: active,
                              onChanged: (_) => _toggleSourceStatus(s['id'], active),
                              activeColor: const Color(0xFF10B981),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (action) {
                                if (action == 'edit') _showEditSourceDialog(s);
                                else if (action == 'delete') {
                                  _showConfirmDialog(
                                    'Hapus Sumber',
                                    'Yakin ingin menghapus "${s['name']}"? Artikel lama tidak akan dihapus, tetapi artikel baru tidak akan diambil lagi.',
                                    () => _deleteSource(s['id']),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            'Belum ada sumber berita',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambahkan sumber baru',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }
}
