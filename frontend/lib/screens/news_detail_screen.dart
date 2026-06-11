import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _isLiking = false;
  bool _isSummarizing = false;
  String? _aiSummary;
  bool _isAiCached = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _toggleLike() async {
    setState(() => _isLiking = true);
    try {
      final success = await NewsService.toggleLike(_item.id, _item.isLiked);
      if (success) {
        setState(() {
          _item.toggleLike();
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
      final success = await NewsService.toggleBookmark(_item.id, _item.isBookmarked);
      if (success) {
        setState(() {
          _item.toggleBookmark();
        });
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

  void _generateSummary({bool force = false}) async {
    if (_isSummarizing) return;
    setState(() => _isSummarizing = true);
    try {
      final result = await NewsService.summarizeArticle(_item.id, force: force);
      if (mounted) {
        setState(() {
          _aiSummary = result['summary'] as String;
          _isAiCached = result['cached'] as bool;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            force
              ? 'AI Summary regenerated!'
              : (_isAiCached ? 'Loaded cached AI summary' : 'AI Summary generated!'),
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  void _shareArticle() async {
    if (_item.sourceUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No source URL to share')),
      );
      return;
    }
    final source = _item.sourceName ?? 'Unknown';
    final category = _item.category != null ? ' • ${_item.category}' : '';
    await Share.share(
      '${_item.title}\n\nvia $source$category\n\n${_item.sourceUrl}',
      subject: _item.title,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme ?? const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: _isLiking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _item.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _item.isLiked ? Colors.red : theme.iconTheme.color ?? Colors.black87,
                  ),
            onPressed: _isLiking ? null : _toggleLike,
          ),
          IconButton(
            icon: _isBookmarking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _item.isBookmarked ? Colors.blue : theme.iconTheme.color ?? Colors.black87,
                  ),
            onPressed: _isBookmarking ? null : _toggleBookmark,
          ),
          IconButton(
            icon: Icon(Icons.share, color: theme.iconTheme.color ?? Colors.black87),
            onPressed: _shareArticle,
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
                  child: Container(color: theme.scaffoldBackgroundColor, height: 250),
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color ?? Colors.black87,
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
                        child: Icon(Icons.public, size: 20, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _item.sourceName ?? 'Unknown Source',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_item.publishedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color ?? Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Divider
                  Divider(color: theme.dividerColor, thickness: 1),
                  const SizedBox(height: 20),

                  // Content
                  Text(
                    _item.originalContent ?? _item.summary,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color ?? Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // AI Summary section
                  if (_aiSummary != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                if (_isAiCached)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'cached',
                                      style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.refresh, size: 18, color: theme.colorScheme.primary),
                                  tooltip: 'Regenerate',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _isSummarizing ? null : () => _generateSummary(force: true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _aiSummary!,
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_aiSummary == null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSummarizing ? null : () => _generateSummary(),
                        icon: _isSummarizing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isSummarizing ? 'Generating...' : 'Generate AI Summary'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
