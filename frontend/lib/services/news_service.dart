import 'dart:convert';
import 'dart:developer' as developer;
import 'api_client.dart';
import '../models/news_item.dart';

class NewsService {
  static Future<Map<String, dynamic>> searchNews({
    required String query,
    String? cursor,
    int limit = 10,
    String? category,
    String? language,
  }) async {
    final queryParams = <String>['q=${Uri.encodeComponent(query)}'];
    if (cursor != null) queryParams.add('cursor=$cursor');
    queryParams.add('limit=$limit');
    if (category != null) queryParams.add('category=$category');
    if (language != null) queryParams.add('language=$language');

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await ApiClient.get('/search$queryString');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) throw Exception('Invalid response: data is null');

      final itemsData = data['data'] as List?;
      if (itemsData == null) throw Exception('Invalid response: data field is missing');

      final items = itemsData.map((i) => NewsItem.fromJson(i)).toList();

      final meta = data['meta'] as Map<String, dynamic>?;
      if (meta == null) throw Exception('Invalid response: meta field is missing');

      return {
        'items': items,
        'nextCursor': meta['nextCursor'],
        'hasMore': meta['hasMore'] ?? false,
      };
    }
    throw Exception('Failed to search: status ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchFeed({
    String? cursor,
    int limit = 10,
    String? category,
    String? language,
    bool personalized = false,
  }) async {
    final queryParams = <String>[];
    if (cursor != null) queryParams.add('cursor=$cursor');
    queryParams.add('limit=$limit');
    if (category != null) queryParams.add('category=$category');
    if (language != null) queryParams.add('language=$language');
    if (personalized) queryParams.add('personalized=true');

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await ApiClient.get('/feed$queryString');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Invalid response: data is null');
      }

      final itemsData = data['data'] as List?;
      if (itemsData == null) {
        throw Exception('Invalid response: data field is missing');
      }

      final items = itemsData.map((i) => NewsItem.fromJson(i)).toList();

      final meta = data['meta'] as Map<String, dynamic>?;
      if (meta == null) {
        throw Exception('Invalid response: meta field is missing');
      }

      return {
        'items': items,
        'nextCursor': meta['nextCursor'],
        'hasMore': meta['hasMore'] ?? false,
      };
    }
    throw Exception('Failed to fetch feed: status ${response.statusCode}');
  }

  static Future<bool> toggleLike(String articleId, bool isCurrentlyLiked) async {
    final endpoint = '/articles/$articleId/like';
    final response = isCurrentlyLiked
        ? await ApiClient.delete(endpoint)
        : await ApiClient.post(endpoint);
    developer.log('toggleLike ${response.statusCode}: ${response.body}', name: 'NewsService');
    if (response.statusCode == 401) {
      throw Exception('Please login to like articles');
    }
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> toggleBookmark(String articleId, bool isCurrentlyBookmarked) async {
    final endpoint = '/articles/$articleId/bookmark';
    final response = isCurrentlyBookmarked
        ? await ApiClient.delete(endpoint)
        : await ApiClient.post(endpoint);

    developer.log('toggleBookmark ${response.statusCode}: ${response.body}', name: 'NewsService');
    if (response.statusCode == 401) {
      throw Exception('Please login to bookmark articles');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  static Future<List<NewsItem>> fetchBookmarks() async {
    final response = await ApiClient.get('/bookmarks');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response: data is null');
      }
      final itemsData = data['data'] as List?;
      if (itemsData == null) {
        throw Exception('Invalid response: data field is missing');
      }
      return itemsData.map((i) => NewsItem.fromJson(i)).toList();
    }
    throw Exception('Failed to fetch bookmarks');
  }

  static Future<Map<String, dynamic>> summarizeArticle(
    String articleId, {
    bool force = false,
  }) async {
    final query = force ? '?force=true' : '';
    final response = await ApiClient.post('/articles/$articleId/summarize$query');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'summary': data['summary'] as String,
        'cached': data['cached'] as bool? ?? false,
        'regenerated': data['regenerated'] as bool? ?? false,
      };
    }
    if (response.statusCode == 401) {
      throw Exception('Please login to use AI features');
    }
    if (response.statusCode == 404) {
      throw Exception('Article not found');
    }
    throw Exception('Failed to generate summary (status ${response.statusCode})');
  }

  static Future<void> recordReadingHistory(String articleId, {double readProgress = 0}) async {
    final response = await ApiClient.post(
      '/reading-history',
      body: {'articleId': articleId, 'readProgress': readProgress},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      developer.log(
        'recordReadingHistory failed: ${response.statusCode} ${response.body}',
        name: 'NewsService',
      );
    }
  }

  static Future<List<NewsItem>> getReadingHistory({int limit = 20}) async {
    final response = await ApiClient.get('/reading-history?limit=$limit');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response: data is null');
      }
      final itemsData = data['data'] as List?;
      if (itemsData == null) {
        throw Exception('Invalid response: data field is missing');
      }
      return itemsData.map((i) => NewsItem.fromJson(i)).toList();
    }
    throw Exception('Failed to fetch reading history (status ${response.statusCode})');
  }
}