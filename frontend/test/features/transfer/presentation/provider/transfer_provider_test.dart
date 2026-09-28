import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'package:fintech_wallet/features/transactions/data/models/transaction_model.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:fintech_wallet/features/transfer/presentation/provider/transfer_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockTransferRepository extends Mock implements TransferRepository {}

void main() {
  late MockTransferRepository repository;
  late TransferNotifier notifier;

  const recipient = Recipient(id: 2, fullName: 'Bob', email: 'bob@example.com');
  final transaction = TransactionModel(
    id: 1,
    type: TransactionType.transferOut,
    amount: 20,
    balanceAfter: 80,
    status: TransactionStatus.completed,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockTransferRepository();
    notifier = TransferNotifier(repository, const Uuid());
  });

  test('setRecipient updates the recipient and generates a new idempotency key', () {
    final keyBefore = notifier.state.idempotencyKey;

    notifier.setRecipient(recipient);

    expect(notifier.state.recipient, recipient);
    expect(notifier.state.idempotencyKey, isNot(keyBefore));
  });

  group('submit', () {
    test('does nothing and returns null when there is no recipient yet', () async {
      notifier.setAmount(10);

      final result = await notifier.submit();

      expect(result, isNull);
      expect(notifier.state.submitting, isFalse);
      verifyNever(
        () => repository.submitTransfer(
          recipientEmail: any(named: 'recipientEmail'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          idempotencyKey: any(named: 'idempotencyKey'),
          note: any(named: 'note'),
        ),
      );
    });

    test('does nothing and returns null when the amount is not positive', () async {
      notifier.setRecipient(recipient);

      final result = await notifier.submit();

      expect(result, isNull);
      expect(notifier.state.submitting, isFalse);
    });

    test('sets submitting true immediately, then false on success, clearing any error', () async {
      notifier.setRecipient(recipient);
      notifier.setAmount(20);

      when(
        () => repository.submitTransfer(
          recipientEmail: any(named: 'recipientEmail'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          idempotencyKey: any(named: 'idempotencyKey'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => transaction);

      // Deliberately not awaited yet - this is the actual regression check
      // for the fix (submitting was previously set to false here instead of
      // true, so a real loading spinner never showed).
      final future = notifier.submit();
      expect(notifier.state.submitting, isTrue);

      final result = await future;

      expect(result, transaction);
      expect(notifier.state.submitting, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('an ApiException sets submitting back to false with the error message, and returns null', () async {
      notifier.setRecipient(recipient);
      notifier.setAmount(20);

      when(
        () => repository.submitTransfer(
          recipientEmail: any(named: 'recipientEmail'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          idempotencyKey: any(named: 'idempotencyKey'),
          note: any(named: 'note'),
        ),
      ).thenThrow(const ApiException('Insufficient balance.', statusCode: 422));

      final result = await notifier.submit();

      expect(result, isNull);
      expect(notifier.state.submitting, isFalse);
      expect(notifier.state.errorMessage, 'Insufficient balance.');
    });

    test('a non-ApiException failure propagates rather than being silently swallowed', () async {
      // TransferNotifier only catches ApiException - unlike AuthNotifier, it
      // has no generic catch-all. Documenting the actual current contract:
      // every other failure (a bug, an unexpected throw) surfaces instead of
      // vanishing into a swallowed, unreported error state.
      notifier.setRecipient(recipient);
      notifier.setAmount(20);

      when(
        () => repository.submitTransfer(
          recipientEmail: any(named: 'recipientEmail'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          idempotencyKey: any(named: 'idempotencyKey'),
          note: any(named: 'note'),
        ),
      ).thenThrow(Exception('unexpected'));

      await expectLater(notifier.submit(), throwsException);
    });
  });
}
