import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    return await remoteDataSource.login(
      email: email,
      password: password,
    );
  }
}