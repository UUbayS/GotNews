import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../screens/news_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result = await NewsService.fetchFeed(cursor: _nextCursor);
      setState(() {
        _items.addAll(result['items']);
        _nextCursor = result['nextCursor'];
        _hasMore = result['hasMore'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: PageView.builder(
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
          // Refresh state when coming back in case bookmark changed
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
                child: Container(color: Colors.black),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                ),
              ),
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
                        return IconButton(
                          iconSize: 32,
                          icon: Icon(
                            item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: item.isBookmarked ? Colors.blue : Colors.white,
                          ),
                          onPressed: () async {
                            final success = await NewsService.toggleBookmark(item.id, item.isBookmarked);
                            if (success) {
                              setState(() {
                                item.toggleBookmark();
                              });
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to update bookmark. Please login first.')),
                                );
                              }
                            }
                          },
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
