import 'package:fintech_wallet/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintech_wallet/features/wallet/data/models/wallet_model.dart';
import 'package:fintech_wallet/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletRemoteDataSource extends Mock implements WalletRemoteDataSource {}

void main() {
  late MockWalletRemoteDataSource remote;
  late WalletRepositoryImpl repository;

  const wallet = WalletModel(
    id: 1,
    name: 'Default',
    currency: 'USD',
    balance: 100,
    isDefault: true,
  );

  setUp(() {
    remote = MockWalletRemoteDataSource();
    repository = WalletRepositoryImpl(remote);
  });

  group('getDefaultWallet', () {
    test('forwards directly to the data source', () async {
      when(() => remote.getDefaultWallet()).thenAnswer((_) async => wallet);

      final result = await repository.getDefaultWallet();

      expect(result, wallet);
    });
  });

  group('getWallets', () {
    test('forwards directly to the data source', () async {
      when(() => remote.getWallets()).thenAnswer((_) async => [wallet]);

      final result = await repository.getWallets();

      expect(result, [wallet]);
    });
  });
}
