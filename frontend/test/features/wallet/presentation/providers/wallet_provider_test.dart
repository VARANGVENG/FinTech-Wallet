import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/core/services/push_notification_service.dart';
import 'package:fintech_wallet/features/authentication/domain/entities/user.dart';
import 'package:fintech_wallet/features/authentication/domain/repositories/auth_repository.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:fintech_wallet/features/wallet/data/models/wallet_model.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:fintech_wallet/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPushNotificationService extends Mock implements PushNotificationService {}

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  const user = User(id: 1, fullName: 'Alice', email: 'alice@example.com', isVerified: true);
  const wallet = WalletModel(id: 1, name: 'Default', currency: 'USD', balance: 100, isDefault: true);

  /// walletProvider/walletsProvider both read authProvider to guard against
  /// no signed-in user. Rather than faking AuthNotifier, this drives the
  /// real one (same technique as NOV-27's auth tests) via mocked
  /// dependencies, so "authenticated" here means what it actually means in
  /// the app - not an assumption about AuthNotifier's internals.
  Future<ProviderContainer> authenticatedContainer(List<Override> extra) async {
    final authRepository = MockAuthRepository();
    final pushService = MockPushNotificationService();
    when(
      () => authRepository.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => user);
    when(() => pushService.registerToken()).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        pushNotificationServiceProvider.overrideWithValue(pushService),
        ...extra,
      ],
    );
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).login(email: 'alice@example.com', password: 'secret');
    return container;
  }

  group('walletProvider', () {
    test('throws StateError when there is no authenticated user', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(container.read(walletProvider.future), throwsStateError);
    });

    test('returns the default wallet once the user is authenticated', () async {
      final walletRepository = MockWalletRepository();
      when(() => walletRepository.getDefaultWallet()).thenAnswer((_) async => wallet);

      final container = await authenticatedContainer([
        walletRepositoryProvider.overrideWithValue(walletRepository),
      ]);

      final result = await container.read(walletProvider.future);

      expect(result, wallet);
    });

    test('propagates a repository failure', () async {
      final walletRepository = MockWalletRepository();
      when(() => walletRepository.getDefaultWallet()).thenThrow(Exception('network down'));

      final container = await authenticatedContainer([
        walletRepositoryProvider.overrideWithValue(walletRepository),
      ]);

      await expectLater(container.read(walletProvider.future), throwsException);
    });
  });

  group('walletsProvider', () {
    test('throws StateError when there is no authenticated user', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(container.read(walletsProvider.future), throwsStateError);
    });

    test('returns every wallet once the user is authenticated', () async {
      final walletRepository = MockWalletRepository();
      when(() => walletRepository.getWallets()).thenAnswer((_) async => const <Wallet>[wallet]);

      final container = await authenticatedContainer([
        walletRepositoryProvider.overrideWithValue(walletRepository),
      ]);

      final result = await container.read(walletsProvider.future);

      expect(result, [wallet]);
    });
  });
}
