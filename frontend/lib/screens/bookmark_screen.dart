import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../widgets/news_list_tile.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => BookmarkScreenState();
}

class BookmarkScreenState extends State<BookmarkScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<NewsItem> _bookmarks = [];
  List<NewsItem> _filteredBookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBookmarks(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredBookmarks = _bookmarks;
      } else {
        final lowerQuery = query.trim().toLowerCase();
        _filteredBookmarks = _bookmarks.where((item) {
          return (item.title.toLowerCase().contains(lowerQuery)) ||
              (item.summary.toLowerCase().contains(lowerQuery)) ||
              (item.sourceName?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  Future<void> fetchBookmarks({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final bookmarks = await NewsService.fetchBookmarks();
      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
          _isLoading = false;
        });
        _filterBookmarks(_searchController.text);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _searchController.text.trim().isNotEmpty;
    final displayItems = isSearchActive ? _filteredBookmarks : _bookmarks;

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Bookmark',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => fetchBookmarks(showLoading: false),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBookmarks,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _filterBookmarks('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayItems.isEmpty
                        ? Center(
                            child: Text(
                              isSearchActive ? 'No bookmarks match your search' : 'No bookmarks yet.',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                            itemCount: displayItems.length,
                            itemBuilder: (context, index) {
                              return NewsListTile(item: displayItems[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
