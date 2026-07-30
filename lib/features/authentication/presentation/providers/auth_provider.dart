import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(status: status ?? this.status, errorMessage: errorMessage);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      // TODO:
      // await authRepository.login(email, password);

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));

      if (email == "admin@gmail.com" && password == "123456") {
        state = state.copyWith(status: AuthStatus.success);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Invalid email or password",
        );
      }
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

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
