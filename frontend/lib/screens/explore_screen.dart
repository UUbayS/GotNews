import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../services/auth_service.dart';
import '../widgets/news_list_tile.dart';
import '../screens/news_detail_screen.dart';
import 'package:provider/provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<NewsItem> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  // Search state
  String _searchQuery = '';
  List<NewsItem> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchHistory = [];
  bool _showSearchHistory = false;

  final List<String> _categories = [
    'All', 'Sports', 'Politics', 'Business', 'Health', 'Travel', 'Science'
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final history = await NewsService.getSearchHistory();
      if (mounted) {
        setState(() => _searchHistory = history);
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    setState(() => _isLoading = true);
    try {
      final categoryFilter = _selectedCategory == 'All' ? null : _selectedCategory.toLowerCase();
      final result = await NewsService.fetchFeed(limit: 20, category: categoryFilter);
      setState(() {
        _items = result['items'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    setState(() => _searchQuery = value);

    if (value.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    if (value.trim().length < 2) return;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().length < 2) return;

    setState(() => _isSearching = true);

    try {
      final categoryFilter = _selectedCategory == 'All' ? null : _selectedCategory.toLowerCase();
      final result = await NewsService.searchNews(
        query: _searchQuery.trim(),
        limit: 20,
        category: categoryFilter,
      );
      if (mounted) {
        setState(() {
          _searchResults = result['items'];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchResults = [];
      _showSearchHistory = false;
    });
    _loadSearchHistory();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (_searchQuery.trim().length >= 2) {
      _performSearch();
    } else {
      _fetchNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _searchQuery.trim().length >= 2;

    NewsItem? trendingItem = _items.isNotEmpty ? _items.first : null;
    List<NewsItem> latestItems = _items.length > 1 ? _items.sublist(1) : [];

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: isSearchActive ? _performSearch : _fetchNews,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Search Bar
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onTap: () {
                    if (_searchController.text.trim().isEmpty && _searchHistory.isNotEmpty) {
                      setState(() => _showSearchHistory = true);
                    }
                  },
                  onSubmitted: (_) => setState(() => _showSearchHistory = false),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: _clearSearch,
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

                // Search History
                if (_showSearchHistory && _searchHistory.isNotEmpty && !isSearchActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                      TextButton(
                        onPressed: () async {
                          await NewsService.clearSearchHistory();
                          setState(() => _searchHistory.clear());
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_searchHistory.take(8).map((h) => GestureDetector(
                      onTap: () {
                        _searchController.text = h['query'];
                        _onSearchChanged(h['query']);
                        setState(() => _showSearchHistory = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(h['query'], style: TextStyle(fontSize: 13, color: textColor)),
                          ],
                        ),
                      ),
                    )).toList()),
                  ),
                ],

                // ----- Search Mode -----
                if (isSearchActive) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(width: 8),
                      if (!_isSearching)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_searchResults.length}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Categories in search mode
                  SizedBox(
                    height: 35,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return GestureDetector(
                          onTap: () => _onCategorySelected(category),
                          child: Container(
                            margin: const EdgeInsets.only(right: 24),
                            padding: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                              child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? textColor : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isSearching)
                    _buildShimmerList()
                  else if (_searchResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return NewsListTile(item: _searchResults[index]);
                      },
                    ),
                ] else ...[
                  // ----- Default Explore Mode -----
                  const SizedBox(height: 24),

                  // Trending Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending News',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (trendingItem != null)
                    _buildTrendingCard(context, trendingItem),

                  const SizedBox(height: 24),

                  // Latest Section
                  Text(
                    'Latest',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // Categories
                  SizedBox(
                    height: 35,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return GestureDetector(
                          onTap: () => _onCategorySelected(category),
                          child: Container(
                            margin: const EdgeInsets.only(right: 24),
                            padding: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? textColor : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Latest List
                  if (!_isLoading)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: latestItems.length,
                      itemBuilder: (context, index) {
                        return NewsListTile(item: latestItems[index]);
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingCard(BuildContext context, NewsItem item) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(item: item),
          ),
        ).then((_) {
          setState(() {});
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? item.imageUrl!
                    : "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=800&q=80",
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.category ?? 'General',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3, color: textColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item.sourceName ?? 'Unknown Source',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatTime(item.publishedAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Unknown';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
