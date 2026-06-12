import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_item.dart';

class CacheService {
  static const String _feedCacheKey = 'cached_feed';
  static const String _feedCacheTimeKey = 'cached_feed_time';
  static const Duration _cacheExpiry = Duration(minutes: 30);

  static Future<void> cacheFeed(List<NewsItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => {
        'id': item.id,
        'title': item.title,
        'summary': item.summary,
        'originalContent': item.originalContent,
        'imageUrl': item.imageUrl,
        'sourceUrl': item.sourceUrl,
        'sourceName': item.sourceName,
        'category': item.category,
        'language': item.language,
        'publishedAt': item.publishedAt?.toIso8601String(),
        'likesCount': item.likesCount,
        'isLiked': item.isLiked,
        'isBookmarked': item.isBookmarked,
      }).toList();

      await prefs.setString(_feedCacheKey, jsonEncode(jsonList));
      await prefs.setInt(_feedCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {}
  }

  static Future<List<NewsItem>?> getCachedFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_feedCacheTimeKey);
      if (cacheTime == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (age > _cacheExpiry.inMilliseconds) return null;

      final cached = prefs.getString(_feedCacheKey);
      if (cached == null) return null;

      final jsonList = jsonDecode(cached) as List;
      return jsonList.map((json) => NewsItem.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedCacheKey);
    await prefs.remove(_feedCacheTimeKey);
  }
}
