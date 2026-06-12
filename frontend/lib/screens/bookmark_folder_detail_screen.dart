import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../widgets/news_list_tile.dart';

class BookmarkFolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const BookmarkFolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<BookmarkFolderDetailScreen> createState() => _BookmarkFolderDetailScreenState();
}

class _BookmarkFolderDetailScreenState extends State<BookmarkFolderDetailScreen> {
  List<NewsItem> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    setState(() => _isLoading = true);
    try {
      final result = await NewsService.getBookmarkFolderDetail(widget.folderId);
      final articles = (result['data']?['articles'] as List? ?? [])
          .map((a) => NewsItem.fromJson(a))
          .toList();
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(widget.folderName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No articles in this folder', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFolder,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      return NewsListTile(item: _articles[index]);
                    },
                  ),
                ),
    );
  }
}
