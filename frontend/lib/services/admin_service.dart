import 'dart:convert';
import 'api_client.dart';
import '../models/user.dart';
import '../models/news_item.dart';

class AdminService {
  // Stats
  static Future<Map<String, dynamic>> fetchStats() async {
    final response = await ApiClient.get('/admin/stats');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_parseError(response.body));
  }

  // Trigger sync
  // Note: sync can take a long time (fetches from many news sources),
  // so we disable the client-side timeout (timeout: null).
  static Future<bool> triggerSync() async {
    final response = await ApiClient.post('/admin/sync', timeout: null);
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  // Users management
  static Future<List<User>> fetchUsers() async {
    final response = await ApiClient.get('/admin/users');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['data'] as List?;
      if (list != null) {
        return list.map((item) => User.fromJson(item)).toList();
      }
      return [];
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> promoteUser(String userId) async {
    final response = await ApiClient.put('/admin/users/$userId/promote');
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> demoteUser(String userId) async {
    final response = await ApiClient.put('/admin/users/$userId/demote');
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> deleteUser(String userId) async {
    final response = await ApiClient.delete('/admin/users/$userId');
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> banUser(String userId, {String? reason, String? duration}) async {
    final response = await ApiClient.put(
      '/admin/users/$userId/ban',
      body: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (duration != null) 'duration': duration,
      },
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> unbanUser(String userId) async {
    final response = await ApiClient.put('/admin/users/$userId/unban');
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  // Articles management
  static Future<Map<String, dynamic>> fetchArticles({
    int limit = 20,
    int page = 1,
    String? category,
    String? source,
    String? search,
  }) async {
    final queryParams = <String>[
      'limit=$limit',
      'page=$page',
    ];
    if (category != null && category != 'All') {
      queryParams.add('category=$category');
    }
    if (source != null && source.isNotEmpty) {
      queryParams.add('source=$source');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    final response = await ApiClient.get('/admin/articles?${queryParams.join('&')}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List?;
      final items = dataList != null
          ? dataList.map((i) => NewsItem.fromJson(i)).toList()
          : <NewsItem>[];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      return {
        'items': items,
        'total': meta['total'] ?? 0,
        'page': meta['page'] ?? 1,
        'totalPages': meta['totalPages'] ?? 1,
      };
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> editArticle(
    String articleId, {
    required String title,
    required String summary,
    required String category,
    required String sourceName,
    String? originalContent,
  }) async {
    final response = await ApiClient.put(
      '/admin/articles/$articleId',
      body: {
        'title': title,
        'summary': summary,
        'category': category,
        'sourceName': sourceName,
        'originalContent': originalContent,
      },
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> deleteArticle(String articleId) async {
    final response = await ApiClient.delete('/admin/articles/$articleId');
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> bulkDeleteArticles({
    List<String>? ids,
    String? sourceName,
  }) async {
    final response = await ApiClient.post(
      '/admin/articles/bulk-delete',
      body: {
        if (ids != null) 'ids': ids,
        if (sourceName != null) 'sourceName': sourceName,
      },
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<Map<String, dynamic>> syncAiSummary(String articleId) async {
    final response = await ApiClient.post('/admin/articles/$articleId/sync-ai-summary');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'summary': body['summary'] as String,
        'generatedAt': body['generatedAt'] as String?,
      };
    }
    throw Exception(_parseError(response.body));
  }

  // Sources management
  static Future<List<Map<String, dynamic>>> fetchSources() async {
    final response = await ApiClient.get('/admin/sources');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['data'] as List?;
      if (list != null) {
        return list.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> addSource({
    required String name,
    required String sourceId,
    required String language,
    bool isActive = true,
  }) async {
    final response = await ApiClient.post(
      '/admin/sources',
      body: {
        'name': name,
        'sourceId': sourceId,
        'language': language,
        'isActive': isActive,
      },
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> editSource(
    String id, {
    String? name,
    bool? isActive,
    String? language,
  }) async {
    final response = await ApiClient.put(
      '/admin/sources/$id',
      body: {
        if (name != null) 'name': name,
        if (isActive != null) 'isActive': isActive,
        if (language != null) 'language': language,
      },
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  static Future<bool> deleteSource(String id) async {
    final response = await ApiClient.delete('/admin/sources/$id');
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(_parseError(response.body));
  }

  // Error parsing helper
  static String _parseError(String responseBody) {
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>?;
      return body?['message'] ?? 'Action failed. Please try again.';
    } catch (_) {
      return 'Server error occurred.';
    }
  }
}
