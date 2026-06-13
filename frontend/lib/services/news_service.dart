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

  static Future<void> recordReadingHistory(String articleId, {double readProgress = 0, int durationSec = 0}) async {
    final response = await ApiClient.post(
      '/reading-history',
      body: {'articleId': articleId, 'readProgress': readProgress, 'durationSec': durationSec},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      developer.log(
        'recordReadingHistory failed: ${response.statusCode} ${response.body}',
        name: 'NewsService',
      );
    }
  }

  static Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    String? countryCode,
    String? city,
    required bool enabled,
  }) async {
    final response = await ApiClient.put('/user/location', body: {
      'latitude': latitude,
      'longitude': longitude,
      if (countryCode != null) 'countryCode': countryCode,
      if (city != null) 'city': city,
      'enabled': enabled,
    });
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<Map<String, dynamic>> fetchLocalFeed({
    required String countryCode,
    String? cursor,
    int limit = 10,
  }) async {
    final queryParams = <String>[
      'country=$countryCode',
      'limit=$limit',
      'personalized=false',
    ];
    if (cursor != null) queryParams.add('cursor=$cursor');
    final response = await ApiClient.get('/feed?${queryParams.join('&')}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final itemsData = data['data'] as List;
      final meta = data['meta'] as Map<String, dynamic>;
      return {
        'items': itemsData.map((i) => NewsItem.fromJson(i)).toList(),
        'nextCursor': meta['nextCursor'],
        'hasMore': meta['hasMore'] ?? false,
      };
    }
    throw Exception('Failed to fetch local feed (${response.statusCode})');
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

  static Future<Map<String, dynamic>> getReadingStats() async {
    final response = await ApiClient.get('/analytics/reading-stats');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch reading stats');
  }

  static Future<List<Map<String, dynamic>>> getSearchHistory() async {
    final response = await ApiClient.get('/search/history');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    return [];
  }

  static Future<void> clearSearchHistory() async {
    await ApiClient.delete('/search/history');
  }

  static Future<List<Map<String, dynamic>>> getBookmarkFolders() async {
    final response = await ApiClient.get('/bookmark-folders');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>> createBookmarkFolder(String name) async {
    final response = await ApiClient.post('/bookmark-folders', body: {'name': name});
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create folder');
  }

  static Future<void> deleteBookmarkFolder(String folderId) async {
    await ApiClient.delete('/bookmark-folders/$folderId');
  }

  static Future<void> addBookmarkToFolder(String folderId, String bookmarkId) async {
    await ApiClient.post('/bookmark-folders/$folderId/items', body: {'bookmarkId': bookmarkId});
  }

  static Future<void> removeBookmarkFromFolder(String folderId, String itemId) async {
    await ApiClient.delete('/bookmark-folders/$folderId/items/$itemId');
  }

  static Future<Map<String, dynamic>> getBookmarkFolderDetail(String folderId) async {
    final response = await ApiClient.get('/bookmark-folders/$folderId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch folder');
  }
}