import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsItem item;

  const NewsDetailScreen({super.key, required this.item});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late NewsItem _item;
  bool _isBookmarking = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _toggleBookmark() async {
    setState(() => _isBookmarking = true);
    try {
      final success = await NewsService.toggleBookmark(_item.id, _item.isBookmarked);
      if (success) {
        setState(() {
          _item.toggleBookmark();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update bookmark. Please check your connection or login status.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: _isBookmarking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _item.isBookmarked ? Colors.blue : Colors.black87,
                  ),
            onPressed: _isBookmarking ? null : _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () {
              // Share functionality here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            if (_item.imageUrl != null && _item.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _item.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white, height: 250),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label
                  if (_item.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _item.category!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    _item.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata (Source and Date)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.public, size: 20, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _item.sourceName ?? 'Unknown Source',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_item.publishedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Divider
                  Divider(color: Colors.grey.shade200, thickness: 1),
                  const SizedBox(height: 20),

                  // Content
                  Text(
                    _item.originalContent ?? _item.summary,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
