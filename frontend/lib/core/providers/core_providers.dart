
import 'package:fintech_wallet/core/biometrics/data/datasource/biometric_local_datasource.dart';
import 'package:fintech_wallet/core/biometrics/data/repositories/biometric_repository_impl.dart';
import 'package:fintech_wallet/core/biometrics/domain/repositories/biometric_repository.dart';
import 'package:fintech_wallet/core/navigation/navigator_key.dart';
import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/auth_interceptor.dart';
import 'package:fintech_wallet/core/services/push_notification_service.dart';
import 'package:fintech_wallet/core/storage/local_storage_service.dart';
import 'package:fintech_wallet/core/storage/secure_storage_service.dart';
import 'package:fintech_wallet/features/notifications/data/datasource/device_token_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [LocalStorageService.create] is async, so this provider can't build the
/// value itself the way the others below do — `main.dart` builds it once,
/// awaited, before `runApp`, and overrides this provider with that instance.
/// If something reads this before main.dart overrides it, that's a real bug
/// (the app started rendering before startup finished) — hence throwing
/// here rather than silently returning a broken default.
final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in main()');
});

/// Synchronous and side-effect-free to construct, so no override needed —
/// this simply builds itself the first time something calls
/// `ref.watch(secureStorageProvider)`.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Depends on [secureStorageProvider] via `ref.watch` — this is the piece
/// that used to break in `MyApp`'s field initializers (one field reading
/// another before it was allowed to). Riverpod resolves this dependency
/// correctly regardless of where each provider is declared.
/// Set once by `main.dart` (`_StartupGateState.initState`) before the app
/// does anything else. Lets a mid-session 401 reset auth state and
/// navigate to `LoginScreen` without this file importing `auth_provider.dart`
/// or a screen — both already import `core_providers.dart`, so importing
/// either back here would be circular.
Future<void> Function()? onSessionExpiredHandler;

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final authInterceptor = AuthInterceptor(
    secureStorage,
    onSessionExpired: () async {
      await onSessionExpiredHandler?.call();
    },
  );
  return ApiClient(authInterceptor: authInterceptor);
});

final deviceTokenRemoteDataSourceProvider = Provider<DeviceTokenRemoteDataSource>((ref) {
  return DeviceTokenRemoteDataSource(ref.watch(apiClientProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    ref.watch(deviceTokenRemoteDataSourceProvider),
    navigatorKey: navigatorKey,
  );
});

/// Domain/repository layer for biometrics (NOV-16). Read directly by
/// `LockScreen` (NOV-18's re-lock gate) via [biometricRepositoryProvider] —
/// there is no separate use-case layer here, matching every other feature
/// in this app (Auth/Wallet/Transfer/TopUp notifiers all call their
/// repository directly too).
final biometricLocalDataSourceProvider = Provider<BiometricLocalDataSource>((ref) {
  return BiometricLocalDataSource();
});

final biometricRepositoryProvider = Provider<BiometricRepository>((ref) {
  return BiometricRepositoryImpl(ref.watch(biometricLocalDataSourceProvider));
});