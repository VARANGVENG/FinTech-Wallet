import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/topup/domain/repositories/topup_repository.dart';
import 'package:fintech_wallet/features/topup/presentation/provider/topup_provider.dart';
import 'package:fintech_wallet/features/transactions/data/models/transaction_model.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockTopUpRepository extends Mock implements TopUpRepository {}

void main() {
  late MockTopUpRepository repository;
  late TopUpNotifier notifier;

  const methods = [
    PaymentMethod(
      type: PaymentMethodType.linkedBank,
      title: 'Linked Bank',
      subtitle: '•••• 1234',
      iconAsset: 'bank',
    ),
  ];
  final transaction = TransactionModel(
    id: 1,
    type: TransactionType.topup,
    amount: 25,
    balanceAfter: 125,
    status: TransactionStatus.completed,
    createdAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(PaymentMethodType.linkedBank);
  });

  setUp(() {
    repository = MockTopUpRepository();
    notifier = TopUpNotifier(repository, const Uuid());
  });

  group('loadPaymentMethods', () {
    test('success populates methods and clears loadingMethods', () async {
      when(() => repository.getPaymentMethods()).thenAnswer((_) async => methods);

      await notifier.loadPaymentMethods();

      expect(notifier.state.methods, methods);
      expect(notifier.state.loadingMethods, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('a failure clears loadingMethods and sets an error message', () async {
      when(() => repository.getPaymentMethods()).thenThrow(Exception('network down'));

      await notifier.loadPaymentMethods();

      expect(notifier.state.loadingMethods, isFalse);
      expect(notifier.state.errorMessage, 'Could not load payment methods.');
    });
  });

  test('setAmount generates a new idempotency key', () {
    final keyBefore = notifier.state.idempotencyKey;

    notifier.setAmount(50);

    expect(notifier.state.amount, 50);
    expect(notifier.state.idempotencyKey, isNot(keyBefore));
  });

  group('submit', () {
    test('sets submitting true immediately, then false on success', () async {
      when(
        () => repository.submitTopUp(
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => transaction);

      // Deliberately not awaited yet - the regression check for the fix
      // (this previously set submitting to false here instead of true, and
      // never reset it to false after a successful submission at all).
      final future = notifier.submit();
      expect(notifier.state.submitting, isTrue);

      final result = await future;

      expect(result, transaction);
      expect(notifier.state.submitting, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('an ApiException sets submitting back to false with the error message, and returns null', () async {
      when(
        () => repository.submitTopUp(
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(const ApiException('Payment declined.', statusCode: 422));

      final result = await notifier.submit();

      expect(result, isNull);
      expect(notifier.state.submitting, isFalse);
      expect(notifier.state.errorMessage, 'Payment declined.');
    });

    test('a non-ApiException failure propagates rather than being silently swallowed', () async {
      // Same contract as TransferNotifier: no generic catch-all here either.
      when(
        () => repository.submitTopUp(
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(Exception('unexpected'));

      await expectLater(notifier.submit(), throwsException);
    });
  });
}
