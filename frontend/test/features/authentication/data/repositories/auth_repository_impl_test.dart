import 'package:fintech_wallet/core/storage/secure_storage_service.dart';
import 'package:fintech_wallet/features/authentication/data/datasource/auth_remote_datasource.dart';
import 'package:fintech_wallet/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:fintech_wallet/features/authentication/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockAuthRemoteDataSource remoteDataSource;
  late MockSecureStorageService secureStorage;
  late AuthRepositoryImpl repository;

  const user = UserModel(id: 1, fullName: 'Alice', email: 'alice@example.com', isVerified: true);

  setUp(() {
    remoteDataSource = MockAuthRemoteDataSource();
    secureStorage = MockSecureStorageService();
    repository = AuthRepositoryImpl(remoteDataSource, secureStorage);
    when(() => secureStorage.saveAuthToken(any())).thenAnswer((_) async {});
    when(() => secureStorage.clearAuthToken()).thenAnswer((_) async {});
  });

  group('login', () {
    test('persists the returned token and returns the user', () async {
      when(
        () => remoteDataSource.login(email: 'alice@example.com', password: 'secret'),
      ).thenAnswer((_) async => (user: user, token: 'tok-123'));

      final result = await repository.login(email: 'alice@example.com', password: 'secret');

      expect(result, user);
      verify(() => secureStorage.saveAuthToken('tok-123')).called(1);
    });
  });

  group('register', () {
    test('persists the returned token and returns the user', () async {
      when(
        () => remoteDataSource.register(
          fullName: 'Alice',
          email: 'alice@example.com',
          password: 'secret',
          passwordConfirmation: 'secret',
        ),
      ).thenAnswer((_) async => (user: user, token: 'tok-456'));

      final result = await repository.register(
        fullName: 'Alice',
        email: 'alice@example.com',
        password: 'secret',
        passwordConfirmation: 'secret',
      );

      expect(result, user);
      verify(() => secureStorage.saveAuthToken('tok-456')).called(1);
    });
  });

  group('me', () {
    test('forwards directly to the remote data source', () async {
      when(() => remoteDataSource.me()).thenAnswer((_) async => user);

      final result = await repository.me();

      expect(result, user);
    });
  });

  group('logout', () {
    test('calls the remote logout and clears the local token', () async {
      when(() => remoteDataSource.logout()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => remoteDataSource.logout()).called(1);
      verify(() => secureStorage.clearAuthToken()).called(1);
    });

    test('still clears the local token when the remote call fails', () async {
      // The whole point of this method's try/catch/finally: a dead network
      // or an already-invalid token must never strand the user mid-logout -
      // clearing the local token is what's actually in our control.
      when(() => remoteDataSource.logout()).thenThrow(Exception('network down'));

      await repository.logout();

      verify(() => secureStorage.clearAuthToken()).called(1);
    });
  });
}
