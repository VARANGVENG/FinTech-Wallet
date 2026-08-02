import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Anything sensitive — auth tokens, refresh tokens, a cached PIN hash —
/// goes through here, never through `SharedPreferences` (see
/// `local_storage_service.dart`), because `SharedPreferences` on Android
/// writes plain XML/plist files with no encryption. `flutter_secure_storage`
/// backs onto Keychain on iOS and EncryptedSharedPreferences/Keystore on
/// Android, which is the whole reason this is a separate class from
/// `LocalStorageService` rather than one "storage service" doing both.
///
/// This is exactly the class `AuthInterceptor` depends on — it calls
/// `getAuthToken()` on every outgoing request and `clearAuthToken()` when a
/// 401 comes back.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> getAuthToken() => _storage.read(key: _authTokenKey);

  Future<void> saveAuthToken(String token) =>
      _storage.write(key: _authTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  /// Called by `AuthInterceptor.onError` on a 401, and by
  /// `ProfileRepositoryImpl.logout()` — the two places a session should
  /// actually end. Clears both tokens together so you can never end up
  /// with a stale refresh token surviving a cleared access token.
  Future<void> clearAuthToken() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> get isLoggedIn async => (await getAuthToken()) != null;
}