import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/app_settings.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

/// `AppSettings` itself doubles as the state here — no separate
/// `SettingsState` wrapper the way `TopUpState`/`TransferState` have.
/// Those needed `loading`/`submitting`/`errorMessage` fields because a
/// network call can be slow or fail; reading/writing local storage is
/// neither slow enough to need a loading spinner nor prone to the kind of
/// failure worth showing an error for.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AppSettings());

  /// Called once from the screen's `initState`, same convention as
  /// `loadPaymentMethods`/`loadRecipient`.
  Future<void> loadSettings() async {
    state = await _repository.loadSettings();
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    await _repository.saveSettings(state);
  }

  Future<void> setTransactionAlerts(bool value) async {
    state = state.copyWith(transactionAlerts: value);
    await _repository.saveSettings(state);
  }

  Future<void> setBiometricLogin(bool value) async {
    state = state.copyWith(biometricLogin: value);
    await _repository.saveSettings(state);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _repository.saveSettings(state);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return SettingsRepositoryImpl(localStorage);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});