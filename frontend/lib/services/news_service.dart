import 'dart:convert';
import 'api_client.dart';
import '../models/news_item.dart';

class NewsService {
  static Future<Map<String, dynamic>> fetchFeed({
    String? cursor,
    int limit = 10,
    String? category,
    String? language,
  }) async {
    final queryParams = [];
    if (cursor != null) queryParams.add('cursor=$cursor');
    queryParams.add('limit=$limit');
    if (category != null) queryParams.add('category=$category');
    if (language != null) queryParams.add('language=$language');

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await ApiClient.get('/feed$queryString');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = (data['data'] as List).map((i) => NewsItem.fromJson(i)).toList();
      return {
        'items': items,
        'nextCursor': data['meta']['nextCursor'],
        'hasMore': data['meta']['hasMore'],
      };
    }
    throw Exception('Failed to fetch feed');
  }

  static Future<bool> toggleLike(String articleId, bool isCurrentlyLiked) async {
    final endpoint = '/articles/$articleId/like';
    final response = isCurrentlyLiked 
        ? await ApiClient.delete(endpoint)
        : await ApiClient.post(endpoint);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> toggleBookmark(String articleId, bool isCurrentlyBookmarked) async {
    final endpoint = '/articles/$articleId/bookmark';
    final response = isCurrentlyBookmarked 
        ? await ApiClient.delete(endpoint)
        : await ApiClient.post(endpoint);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  static Future<List<NewsItem>> fetchBookmarks() async {
    final response = await ApiClient.get('/bookmarks');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List).map((i) => NewsItem.fromJson(i)).toList();
    }
    throw Exception('Failed to fetch bookmarks');
  }
}
