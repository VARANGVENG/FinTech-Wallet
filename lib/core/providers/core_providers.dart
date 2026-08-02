
import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/auth_interceptor.dart';
import 'package:fintech_wallet/core/storage/local_storage_service.dart';
import 'package:fintech_wallet/core/storage/secure_storage_service.dart';
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