import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/admin_service.dart';
import '../models/news_item.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  List<NewsItem> _articles = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All', 'Sports', 'Politics', 'Business', 'Health', 'Travel', 'Science'
  ];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _currentPage = 1;
      });
      _fetchArticles();
      return;
    }
    if (value.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
        _currentPage = 1;
      });
      _fetchArticles();
    });
  }

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final result = await AdminService.fetchArticles(
        page: _currentPage,
        limit: 15,
        category: _selectedCategory == 'All' ? null : _selectedCategory.toLowerCase(),
        search: _searchQuery,
      );
      setState(() {
        _articles = result['items'];
        _totalCount = result['total'];
        _totalPages = result['totalPages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat artikel: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteArticle(String id) async {
    try {
      await AdminService.deleteArticle(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Artikel berhasil dihapus'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchArticles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus artikel: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _regenerateAiSummary(String id) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meregenerasi AI Summary...'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    try {
      await AdminService.syncAiSummary(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI Summary berhasil diregenerasi!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchArticles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal generate summary: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditArticleDialog(NewsItem item) {
    final titleController = TextEditingController(text: item.title);
    final summaryController = TextEditingController(text: item.summary);
    final sourceController = TextEditingController(text: item.sourceName);
    final contentController = TextEditingController(text: item.originalContent);
    final availableCategories = _categories.where((c) => c != 'All').toList();
    String selectedCategory = item.category != null
        ? availableCategories.firstWhere(
            (c) => c.toLowerCase() == item.category!.toLowerCase(),
            orElse: () => availableCategories.first,
          )
        : availableCategories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Artikel', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Ringkasan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sourceController,
                  decoration: InputDecoration(
                    labelText: 'Nama Sumber',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Isi Artikel',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedCategory = val);
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
                final title = titleController.text.trim();
                final summary = summaryController.text.trim();
                final source = sourceController.text.trim();
                final content = contentController.text.trim();
                if (title.isEmpty || summary.isEmpty || source.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await AdminService.editArticle(
                    item.id,
                    title: title,
                    summary: summary,
                    category: selectedCategory,
                    sourceName: source,
                    originalContent: content,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Artikel berhasil diupdate'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  _fetchArticles();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal update artikel: $e'),
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
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteDialog() {
    String? selectedSource;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Bulk Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih sumber berita untuk menghapus semua artikelnya:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Sumber',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _articles
                    .map((a) => a.sourceName)
                    .where((s) => s != null)
                    .toSet()
                    .map((s) => DropdownMenuItem(value: s, child: Text(s!)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedSource = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedSource == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      _showConfirmDialog(
                        'Konfirmasi Bulk Delete',
                        'Yakin ingin menghapus semua artikel dari "$selectedSource"? Tindakan ini tidak dapat dibatalkan.',
                        () async {
                          try {
                            await AdminService.bulkDeleteArticles(sourceName: selectedSource);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Bulk delete berhasil'),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            _fetchArticles();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal bulk delete: $e'),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article, color: Color(0xFFF59E0B), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Kelola Artikel',
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
            icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 22),
            onPressed: _showBulkDeleteDialog,
            tooltip: 'Bulk Delete',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.54) ?? Colors.black54),
            onPressed: _fetchArticles,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildTotalCount(),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _articles.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchArticles,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _articles.length,
                          itemBuilder: (context, index) => _buildArticleCard(_articles[index]),
                        ),
                      ),
          ),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cari judul artikel...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                    _fetchArticles();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                  _currentPage = 1;
                });
                _fetchArticles();
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Total: $_totalCount artikel',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildArticleCard(NewsItem a) {
    return GestureDetector(
      onTap: () => _showArticleDetail(a),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 90,
              height: 90,
              child: CachedNetworkImage(
                imageUrl: a.imageUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Theme.of(context).dividerColor),
                errorWidget: (c, u, e) => Container(
                  color: Theme.of(context).dividerColor,
                  child: Icon(Icons.article_outlined, color: Theme.of(context).dividerColor, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (a.category ?? 'GENERAL').toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.sourceName ?? 'Unknown',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text('${a.likesCount}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(width: 10),
                    Icon(Icons.bookmark_border, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text('${a.bookmarksCount}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) {
              if (action == 'detail') _showArticleDetail(a);
              else if (action == 'edit') _showEditArticleDialog(a);
              else if (action == 'sync-ai') _regenerateAiSummary(a.id);
              else if (action == 'delete') {
                _showConfirmDialog(
                  'Hapus Artikel',
                  'Yakin ingin menghapus artikel ini? Tindakan ini tidak dapat dibatalkan.',
                  () => _deleteArticle(a.id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'detail',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Lihat Detail'),
                  ],
                ),
              ),
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
                value: 'sync-ai',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Regen AI Summary'),
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
    ),
    );
  }

  void _showArticleDetail(NewsItem a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Image
              if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: a.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Theme.of(context).dividerColor,
                    ),
                    errorWidget: (c, u, e) => Container(
                      height: 200,
                      color: Theme.of(context).dividerColor,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    if (a.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.category!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      a.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meta info
                    Row(
                      children: [
                        Icon(Icons.public, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          a.sourceName ?? 'Unknown Source',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(a.publishedAt),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${a.likesCount}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(width: 16),
                        Icon(Icons.bookmark_border, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${a.bookmarksCount}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    // Summary
                    Text(
                      'Ringkasan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.summary,
                      style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, height: 1.6),
                    ),

                    // Original content
                    if (a.originalContent != null && a.originalContent!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 16),
                      Text(
                        'Konten Asli',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.originalContent!,
                        style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, height: 1.6),
                      ),
                    ],
                    const SizedBox(height: 30),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditArticleDialog(a);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _regenerateAiSummary(a.id);
                            },
                            icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                            label: const Text('Regen AI'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5CF6),
                              side: const BorderSide(color: Color(0xFF8B5CF6)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showConfirmDialog(
                                'Hapus Artikel',
                                'Yakin ingin menghapus artikel ini?',
                                () => _deleteArticle(a.id),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Hapus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _fetchArticles();
                  }
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: _currentPage > 1 ? AppColors.primary : Theme.of(context).dividerColor),
            ),
            child: Text(
              'Prev',
              style: TextStyle(
                color: _currentPage > 1 ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          OutlinedButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _fetchArticles();
                  }
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(
                color: _currentPage < _totalPages ? AppColors.primary : Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              'Next',
              style: TextStyle(
                color: _currentPage < _totalPages ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            'Tidak ada artikel ditemukan',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 114,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }
}
