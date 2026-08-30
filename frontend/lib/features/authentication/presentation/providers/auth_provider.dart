import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/features/authentication/data/datasource/auth_remote_datasource.dart';
import 'package:fintech_wallet/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:fintech_wallet/features/authentication/domain/entities/user.dart';
import 'package:fintech_wallet/features/authentication/domain/repositories/auth_repository.dart';
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

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success, user: user);
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
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _repository.logout();
        state = const AuthState();
      }
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(AuthRemoteDataSource(apiClient), secureStorage);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});