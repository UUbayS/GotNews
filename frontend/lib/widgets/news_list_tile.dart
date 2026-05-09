import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../screens/news_detail_screen.dart';

class NewsListTile extends StatefulWidget {
  final NewsItem item;
  final VoidCallback? onTap;

  const NewsListTile({super.key, required this.item, this.onTap});

  @override
  State<NewsListTile> createState() => _NewsListTileState();
}

class _NewsListTileState extends State<NewsListTile> {
  bool _isBookmarking = false;

  void _toggleBookmark() async {
    setState(() => _isBookmarking = true);
    try {
      final success = await NewsService.toggleBookmark(widget.item.id, widget.item.isBookmarked);
      if (success) {
        setState(() {
          widget.item.toggleBookmark();
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.onTap != null) widget.onTap!();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(item: widget.item),
          ),
        ).then((_) {
          // Refresh state when coming back in case bookmark changed
          setState(() {});
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty)
                      ? widget.item.imageUrl!
                      : "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=300&q=80",
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
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.category ?? 'General',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        widget.item.sourceName ?? 'Unknown Source',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(widget.item.publishedAt),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // More options
            Column(
              children: [
                IconButton(
                  icon: _isBookmarking 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          widget.item.isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                          color: widget.item.isBookmarked ? Colors.blue : Colors.grey
                        ),
                  onPressed: _isBookmarking ? null : _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
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
