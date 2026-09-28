import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/topup/data/datasource/topup_remote_datasource.dart';
import 'package:fintech_wallet/features/topup/data/repositories/topup_repository_impl.dart';
import 'package:fintech_wallet/features/transactions/data/models/transaction_model.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTopUpRemoteDataSource extends Mock implements TopUpRemoteDataSource {}

void main() {
  late MockTopUpRemoteDataSource remote;
  late TopUpRepositoryImpl repository;

  setUp(() {
    remote = MockTopUpRemoteDataSource();
    repository = TopUpRepositoryImpl(remote);
  });

  group('getPaymentMethods', () {
    test('forwards directly to the data source', () async {
      const methods = [
        PaymentMethod(
          type: PaymentMethodType.linkedBank,
          title: 'Linked Bank',
          subtitle: '•••• 1234',
          iconAsset: 'bank',
        ),
      ];
      when(() => remote.getPaymentMethods()).thenAnswer((_) async => methods);

      final result = await repository.getPaymentMethods();

      expect(result, methods);
    });
  });

  group('submitTopUp', () {
    test('forwards every field to the data source and returns the transaction', () async {
      final transaction = TransactionModel(
        id: 1,
        type: TransactionType.topup,
        amount: 25,
        balanceAfter: 125,
        status: TransactionStatus.completed,
        createdAt: DateTime(2026, 1, 1),
      );

      when(
        () => remote.submitTopUp(
          amount: 25,
          currency: 'USD',
          method: PaymentMethodType.linkedBank,
          idempotencyKey: 'key-1',
        ),
      ).thenAnswer((_) async => transaction);

      final result = await repository.submitTopUp(
        amount: 25,
        currency: 'USD',
        method: PaymentMethodType.linkedBank,
        idempotencyKey: 'key-1',
      );

      expect(result, transaction);
    });
  });
}
