import 'package:fintech_wallet/core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl(this.remoteDataSource, this.secureStorage);

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final result = await remoteDataSource.login(email: email, password: password);
    await secureStorage.saveAuthToken(result.token);
    return result.user;
  }

  @override
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await remoteDataSource.register(
      fullName: fullName,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await secureStorage.saveAuthToken(result.token);
    return result.user;
  }

  @override
  Future<User> me() async {
    return remoteDataSource.me();
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Best-effort server-side revocation. If it fails (no network, token
      // already invalid), there's nothing actionable the user can do about
      // it and no reason to block them from leaving — the token is cleared
      // locally either way, below, which is what's actually in our control.
    } finally {
      await secureStorage.clearAuthToken();
    }
  }
}