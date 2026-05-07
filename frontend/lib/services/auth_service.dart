import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await ApiClient.storage.read(key: 'accessToken');
    if (token != null) {
      try {
        final response = await ApiClient.get('/auth/me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _currentUser = User.fromJson(data['user']);
        } else {
          await logout();
        }
      } catch (e) {
        // Network error, maybe stay logged in or handle gracefully
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.storage.write(key: 'accessToken', value: data['accessToken']);
        await ApiClient.storage.write(key: 'refreshToken', value: data['refreshToken']);
        _currentUser = User.fromJson(data['user']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.storage.write(key: 'accessToken', value: data['accessToken']);
        await ApiClient.storage.write(key: 'refreshToken', value: data['refreshToken']);
        _currentUser = User.fromJson(data['user']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  Future<void> logout() async {
    await ApiClient.storage.delete(key: 'accessToken');
    await ApiClient.storage.delete(key: 'refreshToken');
    _currentUser = null;
    notifyListeners();
  }
}
