import 'package:fintech_wallet/core/storage/local_storage_service.dart';
import '../model/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Wraps [LocalStorageService] directly — no remote data source layer,
/// since Settings is deliberately local-only. Reuses the same generic
/// `cacheJson`/`readCachedJson` methods `hasSeenOnboarding` already relies
/// on, just with a key scoped to this feature.
class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageService _localStorage;

  SettingsRepositoryImpl(this._localStorage);

  static const _settingsKey = 'app_settings';

  @override
  Future<AppSettings> loadSettings() async {
    final json = _localStorage.readCachedJson(_settingsKey);
    if (json == null) return const AppSettings();
    return AppSettings.fromJson(json);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _localStorage.cacheJson(_settingsKey, settings.toJson());
  }
}