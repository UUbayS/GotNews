import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrlAndroid = 'http://10.0.2.2:3000/api';
  static const String _baseUrlIOS = 'http://localhost:3000/api';
  static const String _baseUrlProduction = 'https://api.gotnews.example.com/api';

  static String get baseUrl {
    // Konfigurasi per platform — ubah sesuai environment
    // Di development emulator Android: 10.0.2.2
    // Di iOS simulator / device: localhost atau IP mesin
    // Di production: URL server sebenarnya
    return _baseUrlAndroid;
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
}