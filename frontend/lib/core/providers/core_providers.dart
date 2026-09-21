
import 'package:fintech_wallet/core/biometrics/data/datasource/biometric_local_datasource.dart';
import 'package:fintech_wallet/core/biometrics/data/repositories/biometric_repository_impl.dart';
import 'package:fintech_wallet/core/biometrics/domain/repositories/biometric_repository.dart';
import 'package:fintech_wallet/core/navigation/navigator_key.dart';
import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/auth_interceptor.dart';
import 'package:fintech_wallet/core/services/biometric_auth_service.dart';
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
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final authInterceptor = AuthInterceptor(
    secureStorage,
    onSessionExpired: () async {
      // e.g. navigate to sign-in — wired once a router exists (see the
      // empty lib/app/router.dart from the earlier audit).
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

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// NOV-006: the new domain/repository layer for biometrics, built
/// alongside — not in place of — [biometricAuthServiceProvider] above.
/// Nothing reads these providers yet; the 3 existing biometric call sites
/// (main.dart, login_screen.dart, settings_provider.dart) still use
/// [biometricAuthServiceProvider] until NOV-007 migrates them.
final biometricLocalDataSourceProvider = Provider<BiometricLocalDataSource>((ref) {
  return BiometricLocalDataSource();
});

final biometricRepositoryProvider = Provider<BiometricRepository>((ref) {
  return BiometricRepositoryImpl(ref.watch(biometricLocalDataSourceProvider));
});