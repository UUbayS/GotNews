import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user.dart';
import 'dart:developer' as developer;

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _onboardingComplete = false;
  String? _lastError;
  BanInfo? _banInfo;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isOnboardingComplete => _onboardingComplete;
  BanInfo? get banInfo => _banInfo;

  void clearBan() {
    if (_banInfo != null) {
      _banInfo = null;
      notifyListeners();
    }
  }

  void _setBanInfo(BanInfo info) {
    _banInfo = info;
    _lastError = info.message;
    notifyListeners();
  }

  AuthService() {
    _isLoading = true;
    _initialize();
  }

  Future<void> _initialize() async {
    await checkSession();
    await _loadOnboardingStatus();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadOnboardingStatus() async {
    final userId = _currentUser?.id;
    if (userId == null) {
      _onboardingComplete = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete_$userId') ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final userId = _currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete_$userId', true);
    _onboardingComplete = true;
    notifyListeners();
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
        } else if (response.statusCode == 403 &&
            _isBanResponse(response.body)) {
          _setBanInfo(_parseBanInfo(response.body)!);
          await logout();
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
      } else if (response.statusCode == 403 &&
          _isBanResponse(response.body)) {
        _setBanInfo(_parseBanInfo(response.body)!);
        await logout();
        return;
      }
    } catch (e) {
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
            await _loadOnboardingStatus();
          }
          notifyListeners();
          return true;
        }
      }

      if (response.statusCode == 403 && _isBanResponse(response.body)) {
        _setBanInfo(_parseBanInfo(response.body)!);
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'];
      
      if (response.statusCode == 401) {
        _lastError = 'Email/username atau password salah.';
      } else if (response.statusCode == 429) {
        _lastError = 'Terlalu banyak percobaan login. Mohon tunggu sebentar.';
      } else if (response.statusCode == 404) {
        _lastError = 'Akun tidak ditemukan. Periksa email/username Anda.';
      } else if (response.statusCode == 500) {
        _lastError = 'Server error. Silakan coba lagi nanti.';
      } else {
        _lastError = message ?? 'Login gagal. Periksa kredensial Anda.';
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
          _onboardingComplete = false;
          final userId = _currentUser?.id ?? 'new';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_complete_$userId', false);
          notifyListeners();
          return true;
        }
      }

      if (response.statusCode == 403 && _isBanResponse(response.body)) {
        _setBanInfo(_parseBanInfo(response.body)!);
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'];
      
      if (response.statusCode == 409) {
        if (message?.contains('Email') ?? false) {
          _lastError = 'Email sudah terdaftar. Gunakan email lain atau coba login.';
        } else if (message?.contains('Username') ?? false) {
          _lastError = 'Username sudah dipakai. Pilih username lain.';
        } else {
          _lastError = 'Akun sudah ada. Silakan login.';
        }
      } else if (response.statusCode == 429) {
        _lastError = 'Terlalu banyak percobaan registrasi. Mohon tunggu sebentar.';
      } else if (response.statusCode == 500) {
        _lastError = 'Server error. Silakan coba lagi nanti.';
      } else {
        _lastError = message ?? 'Registrasi gagal. Silakan coba lagi.';
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
    _onboardingComplete = false;
    _lastError = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _lastError = null;
    try {
      final response = await ApiClient.delete('/auth/account');
      if (response.statusCode == 200) {
        await logout();
        return true;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      _lastError = body?['message'] ?? 'Failed to delete account';
    } catch (e) {
      _lastError = 'Unable to connect to server';
    }
    notifyListeners();
    return false;
  }

  void refresh() {
    notifyListeners();
  }

  bool _isBanResponse(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final code = data['code'];
        return code == 'ACCOUNT_BANNED' || code == 'EMAIL_BANNED';
      }
    } catch (_) {}
    return false;
  }

  BanInfo? _parseBanInfo(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return BanInfo(
        code: data['code'] as String? ?? 'ACCOUNT_BANNED',
        message: data['message'] as String? ?? 'Akun Anda telah di-ban.',
        reason: data['reason'] as String?,
        expiresAt: data['expiresAt'] != null
            ? DateTime.tryParse(data['expiresAt'].toString())
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}