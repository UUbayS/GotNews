# Fix FlutterSecureStorage Hang on Xiaomi/MIUI

## Problem
`AuthService` constructor calls `_checkAuthStatus()` → `FlutterSecureStorage.read()` hangs forever on Xiaomi KeyStore bug. `_isLoading` never becomes `false` → app stuck on `CircularProgressIndicator`.

## Files to change
- `frontend/lib/services/auth_service.dart`

## Approach
Wrap `_checkAuthStatus()` with a timer-based guard. If storage read doesn't resolve within 3 seconds, force `_isLoading = false` and move on (assume no token).

### auth_service.dart changes

Modify constructor and add `_initAuth`:

```dart
AuthService() {
  _initAuth();
}

void _initAuth() {
  _checkAuthStatus().timeout(
    const Duration(seconds: 3),
    onTimeout: () {
      _isLoading = false;
      _lastError = null;
      notifyListeners();
    },
  );
}

Future<void> _checkAuthStatus() async {
  // ... existing code unchanged ...
}
```

No other file changes needed. Storage read itself stays as-is — just guarded by timeout so it can never block app startup.

## Verification
1. Run app on Xiaomi device
2. Loading spinner disappears within 3 seconds max
3. Guest mode works normally without token
4. Logged-in user still auto-authenticates if storage reads fast enough
