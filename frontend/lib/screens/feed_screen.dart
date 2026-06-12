import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../services/auth_service.dart';
import '../screens/news_detail_screen.dart';
import '../screens/login_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  final List<NewsItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _error;
  bool _isRefreshing = false;
  @override
  void initState() {
    super.initState();
    _fetchNextPage();
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      _items.clear();
      _nextCursor = null;
      _hasMore = true;
      final result = await NewsService.fetchFeed(
        cursor: null,
        personalized: true,
      );
      setState(() {
        _items.addAll(result['items']);
        _nextCursor = result['nextCursor'];
        _hasMore = result['hasMore'];
        _isRefreshing = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        if (_items.isEmpty) {
          _error = 'Failed to load articles. Check your connection.';
        }
      });
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isFirstPage = _nextCursor == null;
      final result = await NewsService.fetchFeed(
        cursor: _nextCursor,
        personalized: isFirstPage ? true : false,
      );
      setState(() {
        _items.addAll(result['items']);
        _nextCursor = result['nextCursor'];
        _hasMore = result['hasMore'];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (_items.isEmpty) {
          _error = 'Failed to load articles. Check your connection.';
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load more articles'),
              action: SnackBarAction(label: 'Retry', onPressed: _fetchNextPage),
            ),
          );
        }
      });
    }
  }

  void _showLoginPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Login to read more articles and access all features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_items.isEmpty && _error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchNextPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length + (_hasMore ? 1 : 0),
            onPageChanged: (index) {
              if (index >= _items.length - 2) {
                _fetchNextPage();
              }
            },
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              final item = _items[index];
              return _buildNewsCard(item);
            },
          ),
          // Pull-to-refresh indicator
          if (_isRefreshing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Refreshing...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Pull-down gesture detector for refresh
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                  _refreshFeed();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item) {
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Fallback
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? item.imageUrl!
                  : "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=800&q=80",
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[800]!,
                child: Container(color: Theme.of(context).scaffoldBackgroundColor),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.image_not_supported, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.24) ?? Colors.white24, size: 50),
                ),
              ),
            ),
          ),

          // Read badge
          if (item.isRead)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
          
          // Dark Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
  
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.category!.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap to read full story",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(
                        '${item.readingTime} min read',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.sourceName ?? 'Unknown Source',
                                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 10),
                              if (item.publishedAt != null)
                                Text(
                                  '• ${item.publishedAt!.day}/${item.publishedAt!.month}/${item.publishedAt!.year}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                            ],
                          ),
                        ]
                      )
                    ),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Likes
                            Column(
                              children: [
                                IconButton(
                                  iconSize: 32,
                                  icon: Icon(
                                    item.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: item.isLiked ? Colors.red : Colors.white,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final success = await NewsService.toggleLike(item.id, item.isLiked);
                                      if (success && context.mounted) {
                                        setState(() {
                                          item.toggleLike();
                                        });
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                        );
                                      }
                                    }
                                  },
                                ),
                                Text(
                                  item.likesCount > 0 ? '${item.likesCount}' : '',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Bookmark
                            Column(
                              children: [
                                IconButton(
                                  iconSize: 32,
                                  icon: Icon(
                                    item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: item.isBookmarked ? Colors.blue : Colors.white,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final success = await NewsService.toggleBookmark(item.id, item.isBookmarked);
                                      if (success && context.mounted) {
                                        setState(() {
                                          item.toggleBookmark();
                                        });
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                        );
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ],
                        );
                      }
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
