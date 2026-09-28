import 'package:fintech_wallet/features/transactions/data/models/transaction_model.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transfer/data/datasource/transfer_remote_datasource.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransferRemoteDataSource extends Mock implements TransferRemoteDataSource {}

void main() {
  late MockTransferRemoteDataSource remote;
  late TransferRepositoryImpl repository;

  const recipient = Recipient(id: 2, fullName: 'Bob', email: 'bob@example.com');

  setUp(() {
    remote = MockTransferRemoteDataSource();
    repository = TransferRepositoryImpl(remote);
  });

  group('findRecipient', () {
    test('forwards the email and returns the recipient', () async {
      when(() => remote.findRecipient('bob@example.com')).thenAnswer((_) async => recipient);

      final result = await repository.findRecipient('bob@example.com');

      expect(result, recipient);
      verify(() => remote.findRecipient('bob@example.com')).called(1);
    });
  });

  group('submitTransfer', () {
    test('forwards every field to the data source and returns the transaction', () async {
      final transaction = TransactionModel(
        id: 1,
        type: TransactionType.transferOut,
        amount: 20,
        balanceAfter: 80,
        status: TransactionStatus.completed,
        createdAt: DateTime(2026, 1, 1),
      );

      when(
        () => remote.submitTransfer(
          recipientEmail: 'bob@example.com',
          amount: 20,
          currency: 'USD',
          idempotencyKey: 'key-1',
          note: 'lunch',
        ),
      ).thenAnswer((_) async => transaction);

      final result = await repository.submitTransfer(
        recipientEmail: 'bob@example.com',
        amount: 20,
        currency: 'USD',
        idempotencyKey: 'key-1',
        note: 'lunch',
      );

      expect(result, transaction);
    });
  });
}
