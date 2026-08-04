import '../../data/model/app_settings.dart';

/// The contract [SettingsNotifier] depends on. Unlike every other
/// repository in this app, there's no "real HTTP implementation, commented
/// out for now" story here — Settings is deliberately local-only
/// (`LocalStorageService`), not something waiting on a backend to exist.
abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}