import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../screens/news_detail_screen.dart';

class NewsListTile extends StatefulWidget {
  final NewsItem item;
  final VoidCallback? onTap;
  final bool isRead;
  final Widget? trailing;

  const NewsListTile({super.key, required this.item, this.onTap, this.isRead = false, this.trailing});

  @override
  State<NewsListTile> createState() => _NewsListTileState();
}

class _NewsListTileState extends State<NewsListTile> {
  bool _isBookmarking = false;
  bool _isLiking = false;

  void _toggleLike() async {
    setState(() => _isLiking = true);
    try {
      final success = await NewsService.toggleLike(widget.item.id, widget.item.isLiked);
      if (success) {
        setState(() {
          widget.item.toggleLike();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _toggleBookmark() async {
    setState(() => _isBookmarking = true);
    try {
      final wasBookmarked = widget.item.isBookmarked;
      final success = await NewsService.toggleBookmark(widget.item.id, wasBookmarked);
      if (success) {
        setState(() => widget.item.toggleBookmark());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(wasBookmarked ? 'Bookmark removed' : 'Bookmarked'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(item: widget.item),
      ),
    ).then((_) {
      // Refresh state when coming back in case bookmark changed
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return InkWell(
      onTap: _navigateToDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
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
                        baseColor: Colors.grey[400]!,
                        highlightColor: Colors.grey[600]!,
                        child: Container(color: theme.cardColor),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.cardColor,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                if (widget.isRead)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
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
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        widget.item.sourceName ?? 'Unknown Source',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(widget.item.publishedAt),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.item.readingTime} min read',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // More options
            Column(
              children: [
                if (widget.trailing != null) widget.trailing!,
                IconButton(
                  icon: _isLiking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          widget.item.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: widget.item.isLiked ? Colors.red : Colors.grey,
                        ),
                  onPressed: _isLiking ? null : _toggleLike,
                ),
                Text(
                  widget.item.likesCount > 0 ? '${widget.item.likesCount}' : '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
                const SizedBox(height: 4),
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