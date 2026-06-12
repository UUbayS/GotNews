import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user.dart';
import 'dart:developer' as developer;

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;
  String? _lastError;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  AuthService() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await ApiClient.storage.read(key: 'accessToken');
    if (token != null) {
      try {
        final response = await ApiClient.get('/auth/me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>?;
          if (data != null && data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
          } else {
            await logout();
          }
        } else {
          await logout();
        }
      } catch (e) {
        developer.log('Auth status check failed: $e', name: 'AuthService');
      }
    }
    _isLoading = false;
    _lastError = null;
    notifyListeners();
  }

  Future<void> checkSession() async {
    final token = await ApiClient.storage.read(key: 'accessToken');
    if (token == null) {
      if (_currentUser != null) {
        _currentUser = null;
        notifyListeners();
      }
      return;
    }
    try {
      final response = await ApiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
          notifyListeners();
        }
      }
      // Don't logout on non-200 — just keep existing session
    } catch (e) {
      // Network error — keep existing session, don't logout
      developer.log('Session check failed: $e', name: 'AuthService');
    }
  }

  Future<bool> login(String identifier, String password) async {
    _lastError = null;
    try {
      final response = await ApiClient.post('/auth/login', body: {
        'identifier': identifier,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data != null) {
          if (data['accessToken'] != null) {
            await ApiClient.storage.write(key: 'accessToken', value: data['accessToken']);
          }
          if (data['refreshToken'] != null) {
            await ApiClient.storage.write(key: 'refreshToken', value: data['refreshToken']);
          }
          if (data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
          }
          notifyListeners();
          return true;
        }
      }

      // Coba parse error message dari response body
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'];
      
      // Map status codes to user-friendly messages
      if (response.statusCode == 401) {
        _lastError = 'Email/username or password is incorrect.';
      } else if (response.statusCode == 429) {
        _lastError = 'Too many login attempts. Please wait a moment and try again.';
      } else if (response.statusCode == 404) {
        _lastError = 'Account not found. Please check your email/username.';
      } else if (response.statusCode == 500) {
        _lastError = 'Server error. Please try again later.';
      } else {
        _lastError = message ?? 'Login failed. Please check your credentials.';
      }
    } catch (e) {
      _lastError = 'Unable to connect to server. Please check your internet connection.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(
    String username,
    String email,
    String password, {
    String? dateOfBirth,
  }) async {
    _lastError = null;
    try {
      final response = await ApiClient.post('/auth/register', body: {
        'username': username,
        'email': email,
        'password': password,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data != null) {
          if (data['accessToken'] != null) {
            await ApiClient.storage.write(key: 'accessToken', value: data['accessToken']);
          }
          if (data['refreshToken'] != null) {
            await ApiClient.storage.write(key: 'refreshToken', value: data['refreshToken']);
          }
          if (data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
          }
          // Clear onboarding flag for new user (per-user key)
          final userId = _currentUser?.id ?? 'new';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_complete_$userId', false);
          notifyListeners();
          return true;
        }
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'];
      
      // Map status codes to user-friendly messages
      if (response.statusCode == 409) {
        if (message?.contains('Email') ?? false) {
          _lastError = 'This email is already registered. Please use a different email or try logging in.';
        } else if (message?.contains('Username') ?? false) {
          _lastError = 'This username is already taken. Please choose a different username.';
        } else {
          _lastError = 'Account already exists. Please try logging in.';
        }
      } else if (response.statusCode == 429) {
        _lastError = 'Too many registration attempts. Please wait a moment and try again.';
      } else if (response.statusCode == 500) {
        _lastError = 'Server error. Please try again later.';
      } else {
        _lastError = message ?? 'Registration failed. Please try again.';
      }
    } catch (e) {
      _lastError = 'Unable to connect to server. Please check your internet connection.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? avatarUrl,
  }) async {
    _lastError = null;
    try {
      final response = await ApiClient.put('/auth/profile', body: {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
        }
        notifyListeners();
        return true;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'];
      
      // Map status codes to user-friendly messages
      if (response.statusCode == 409) {
        _lastError = 'Username or email already taken. Please choose a different one.';
      } else if (response.statusCode == 429) {
        _lastError = 'Too many requests. Please wait a moment and try again.';
      } else if (response.statusCode == 500) {
        _lastError = 'Server error. Please try again later.';
      } else {
        _lastError = message ?? 'Failed to update profile. Please try again.';
      }
    } catch (e) {
      _lastError = 'Unable to connect to server. Please check your internet connection.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await ApiClient.storage.delete(key: 'accessToken');
    await ApiClient.storage.delete(key: 'refreshToken');
    _currentUser = null;
    _lastError = null;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}