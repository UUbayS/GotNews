import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _developmentUrl = 'http://localhost:3000/api';
  static const String _uploadsBaseUrl = 'http://localhost:3000';

  static String get baseUrl => _developmentUrl;

  static String getAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    return '$_uploadsBaseUrl$avatarUrl';
  }

  static const storage = FlutterSecureStorage();

  static Future<String?> _refreshToken() async {
    final refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final newToken = data['accessToken'] as String;
          await storage.write(key: 'accessToken', value: newToken);
          developer.log('Token refreshed successfully', name: 'ApiClient');
          return newToken;
        }
      } catch (e) {
        developer.log('Token refresh failed: $e', name: 'ApiClient');
      }
    }
    return null;
  }

  static Future<Map<String, String>> _getHeaders({bool hasBody = false}) async {
    try {
      final token = await storage.read(key: 'accessToken');
      developer.log('Token read: ${token != null ? "present (${token.length} chars)" : "null"}', name: 'ApiClient');
      return {
        if (hasBody) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      developer.log('Failed to read token from storage: $e', name: 'ApiClient');
      return {
        if (hasBody) 'Content-Type': 'application/json',
      };
    }
  }

  static Future<http.Response> _retryOnAuthFailure(
    Future<http.Response> Function() requestFn,
  ) async {
    final response = await requestFn();
    if (response.statusCode == 401) {
      developer.log('Got 401, attempting token refresh...', name: 'ApiClient');
      final newToken = await _refreshToken();
      if (newToken != null) {
        return requestFn();
      }
      developer.log('Token refresh failed — session expired', name: 'ApiClient');
    }
    return response;
  }

  static Future<http.Response> get(String endpoint) async {
    return _retryOnAuthFailure(() async {
      final headers = await _getHeaders();
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    });
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _retryOnAuthFailure(() async {
      final headers = await _getHeaders(hasBody: body != null);
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _retryOnAuthFailure(() async {
      final headers = await _getHeaders(hasBody: body != null);
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> delete(String endpoint) async {
    return _retryOnAuthFailure(() async {
      final headers = await _getHeaders();
      return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    });
  }

  static Future<http.Response> postFile(String endpoint, String filePath, String fieldName) async {
    return _retryOnAuthFailure(() async {
      final token = await storage.read(key: 'accessToken');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    });
  }
}