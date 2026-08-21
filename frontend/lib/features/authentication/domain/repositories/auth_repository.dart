import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<void> logout();
}