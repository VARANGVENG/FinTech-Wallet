import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// For everything that is NOT sensitive: "has the user seen onboarding",
/// a cached copy of `AppSettings` for instant app-open (before the network
/// call in `SettingsProvider.load()` resolves), last-viewed tab, etc.
///
/// Deliberately separate from `SecureStorageService` — mixing an auth
/// token into the same unencrypted `SharedPreferences` file as UI flags
/// would be an easy way to accidentally leak it. If a value could ever be
/// sensitive, it belongs in `SecureStorageService` instead, not here.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Async factory instead of a plain constructor because
  /// `SharedPreferences.getInstance()` is itself async — this is the one
  /// `await` call `main.dart` needs before building the rest of the
  /// dependency chain (see the usage note below).
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  static const _hasSeenOnboardingKey = 'has_seen_onboarding';

  bool get hasSeenOnboarding => _prefs.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_hasSeenOnboardingKey, value);

  /// Stores a raw JSON string rather than a typed object — this class
  /// lives in `core/`, so it can't import a feature-specific model like
  /// `AppSettings` (that would create a dependency pointing the wrong
  /// direction, from core into a feature). The caller — e.g.
  /// `SettingsRepositoryImpl` — does the encode/decode with its own model.
  Future<void> cacheJson(String key, Map<String, dynamic> json) =>
      _prefs.setString(key, jsonEncode(json));

  Map<String, dynamic>? readCachedJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearAll() => _prefs.clear();
}