import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'package:fintech_wallet/core/services/push_notification_service.dart';
import 'package:fintech_wallet/features/authentication/domain/entities/user.dart';
import 'package:fintech_wallet/features/authentication/domain/repositories/auth_repository.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPushNotificationService extends Mock implements PushNotificationService {}

void main() {
  late MockAuthRepository repository;
  late MockPushNotificationService pushService;
  late AuthNotifier notifier;

  const user = User(id: 1, fullName: 'Alice', email: 'alice@example.com', isVerified: true);

  setUp(() {
    repository = MockAuthRepository();
    pushService = MockPushNotificationService();
    notifier = AuthNotifier(repository, pushService);
    when(() => pushService.registerToken()).thenAnswer((_) async {});
    when(() => pushService.unregisterToken()).thenAnswer((_) async {});
  });

  group('login', () {
    test('success sets status to success with the returned user and registers the push token', () async {
      when(
        () => repository.login(email: any(named: 'email'), password: any(named: 'password')),
      ).thenAnswer((_) async => user);

      await notifier.login(email: 'alice@example.com', password: 'secret');

      expect(notifier.state.status, AuthStatus.success);
      expect(notifier.state.user, user);
      expect(notifier.state.errorMessage, isNull);
      verify(() => pushService.registerToken()).called(1);
    });

    test('an ApiException sets status to error with the exception message', () async {
      when(
        () => repository.login(email: any(named: 'email'), password: any(named: 'password')),
      ).thenThrow(const ApiException('Invalid credentials', statusCode: 401));

      await notifier.login(email: 'alice@example.com', password: 'wrong');

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, 'Invalid credentials');
      expect(notifier.state.user, isNull);
    });

    test('a non-ApiException failure sets status to error with toString()', () async {
      when(
        () => repository.login(email: any(named: 'email'), password: any(named: 'password')),
      ).thenThrow(Exception('socket closed'));

      await notifier.login(email: 'alice@example.com', password: 'secret');

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, contains('socket closed'));
    });
  });

  group('register', () {
    test('success sets status to success with the returned user and registers the push token', () async {
      when(
        () => repository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenAnswer((_) async => user);

      await notifier.register(
        fullName: 'Alice',
        email: 'alice@example.com',
        password: 'secret',
        passwordConfirmation: 'secret',
      );

      expect(notifier.state.status, AuthStatus.success);
      expect(notifier.state.user, user);
      verify(() => pushService.registerToken()).called(1);
    });

    test('an ApiException sets status to error with the exception message', () async {
      when(
        () => repository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenThrow(const ApiException('Email already taken', statusCode: 422));

      await notifier.register(
        fullName: 'Alice',
        email: 'alice@example.com',
        password: 'secret',
        passwordConfirmation: 'secret',
      );

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, 'Email already taken');
    });
  });

  group('restoreSession', () {
    test('success sets status to success with the returned user', () async {
      when(() => repository.me()).thenAnswer((_) async => user);

      await notifier.restoreSession();

      expect(notifier.state.status, AuthStatus.success);
      expect(notifier.state.user, user);
      verify(() => pushService.registerToken()).called(1);
    });

    test('a 401 logs out and resets state to initial', () async {
      when(() => repository.me()).thenThrow(const ApiException('Unauthenticated.', statusCode: 401));
      when(() => repository.logout()).thenAnswer((_) async {});

      await notifier.restoreSession();

      verify(() => repository.logout()).called(1);
      expect(notifier.state.status, AuthStatus.initial);
      expect(notifier.state.user, isNull);
    });

    test('a non-401 failure (offline/5xx) leaves the existing state unchanged', () async {
      // Deliberate existing behavior (see the notifier's own comment): a
      // failed connectivity check is not grounds to bounce the user to
      // LoginScreen, unlike a confirmed 401.
      when(() => repository.me()).thenThrow(const ApiException('Server error', statusCode: 500));

      await notifier.restoreSession();

      verifyNever(() => repository.logout());
      expect(notifier.state.status, AuthStatus.initial);
    });
  });

  group('logout', () {
    test('unregisters the push token, calls the repository, and resets state to initial', () async {
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => user);
      when(() => repository.logout()).thenAnswer((_) async {});
      await notifier.login(email: 'alice@example.com', password: 'secret');
      expect(notifier.state.status, AuthStatus.success);

      await notifier.logout();

      verify(() => pushService.unregisterToken()).called(1);
      verify(() => repository.logout()).called(1);
      expect(notifier.state.status, AuthStatus.initial);
      expect(notifier.state.user, isNull);
    });
  });
}
