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

/// Now depends on [AuthRepository] — the domain-layer abstraction, not
/// `AuthRepositoryImpl` or `AuthRemoteDataSource` directly. Same principle
/// `TopUpNotifier` follows: this class only knows "something that can log
/// a user in," not how that actually happens underneath.
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
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const AuthState();
  }
}

/// [AuthRemoteDataSource] is still the hardcoded mock it always was — no
/// backend exists yet to call for real (see the earlier audit). What's
/// different now is that this is the ONLY place that mock check lives,
/// instead of being duplicated in `AuthNotifier` as well.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteDataSource());
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
