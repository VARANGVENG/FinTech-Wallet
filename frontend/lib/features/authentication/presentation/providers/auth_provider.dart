import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/core/services/push_notification_service.dart';
import 'package:fintech_wallet/features/authentication/data/datasource/auth_remote_datasource.dart';
import 'package:fintech_wallet/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:fintech_wallet/features/authentication/domain/entities/user.dart';
import 'package:fintech_wallet/features/authentication/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final User? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({AuthStatus? status, String? errorMessage, User? user}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final PushNotificationService _pushService;

  AuthNotifier(this._repository, this._pushService) : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success, user: user);
      await _registerPushTokenSilently();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(status: AuthStatus.success, user: user);
      await _registerPushTokenSilently();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> restoreSession() async {
    try {
      final user = await _repository.me();
      state = state.copyWith(status: AuthStatus.success, user: user);
      await _registerPushTokenSilently();
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _repository.logout();
        state = const AuthState();
      }
    }
  }

  Future<void> logout() async {
    // Unregister while the Sanctum token is still valid - after
    // _repository.logout() revokes it, this call would just 401. Best-effort,
    // same treatment AuthRepositoryImpl.logout() gives its own remote call:
    // push cleanup must never block the user from actually signing out.
    await _unregisterPushTokenSilently();
    await _repository.logout();
    state = const AuthState();
  }

  /// Registering the push token is a side effect of a successful login,
  /// never part of what defines success - a failure here (no network, FCM
  /// unavailable) must not flip AuthStatus away from success.
  Future<void> _registerPushTokenSilently() async {
    try {
      await _pushService.registerToken();
    } catch (e) {
      debugPrint('AuthNotifier: push token registration failed: $e');
    }
  }

  Future<void> _unregisterPushTokenSilently() async {
    try {
      await _pushService.unregisterToken();
    } catch (e) {
      debugPrint('AuthNotifier: push token unregistration failed: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(AuthRemoteDataSource(apiClient), secureStorage);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final pushService = ref.watch(pushNotificationServiceProvider);
  return AuthNotifier(repository, pushService);
}
);
