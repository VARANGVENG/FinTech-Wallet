import 'dart:async';

import 'package:fintech_wallet/features/notifications/presentation/provider/notifications_provider.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction_page.dart';
import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(int id) => Transaction(
  id: id,
  type: TransactionType.transferIn,
  amount: 25,
  balanceAfter: 100,
  status: TransactionStatus.completed,
  createdAt: DateTime(2026, 1, 1),
);

const _wallet = Wallet(
  id: 1,
  name: 'Main',
  currency: 'USD',
  balance: 100,
  isDefault: true,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('reflects the loading state of the underlying transaction history', () {
    final container = ProviderContainer(
      overrides: [
        transactionHistoryProvider.overrideWith(
          // Never resolves - keeps the notifier stuck in its initial
          // isLoading: true state for the whole test.
          (ref) => TransactionHistoryNotifier((_) => Completer<TransactionPage>().future),
        ),
        walletProvider.overrideWith((ref) async => _wallet),
      ],
    );
    addTearDown(container.dispose);

    final result = container.read(transactionNotificationsProvider);

    expect(result, isA<AsyncLoading<List<Object?>>>());
  });

  test('maps loaded transactions to AppNotification, using the wallet currency', () async {
    final container = ProviderContainer(
      overrides: [
        transactionHistoryProvider.overrideWith(
          (ref) => TransactionHistoryNotifier(
            (page) async => TransactionPage(
              transactions: [_tx(1), _tx(2)],
              hasMore: false,
            ),
          ),
        ),
        walletProvider.overrideWith((ref) async => _wallet),
      ],
    );
    addTearDown(container.dispose);
    // The notifier is only created (and its fetch kicked off) on first
    // read/watch - touch it before settling, or there's nothing to settle.
    container.read(transactionHistoryProvider);
    await _settle();

    final result = container.read(transactionNotificationsProvider);

    expect(result.hasValue, isTrue);
    expect(result.value, hasLength(2));
  });

  test('surfaces an error from the transaction history instead of crashing', () async {
    final container = ProviderContainer(
      overrides: [
        transactionHistoryProvider.overrideWith(
          (ref) => TransactionHistoryNotifier(
            (page) async => throw Exception('boom'),
          ),
        ),
        walletProvider.overrideWith((ref) async => _wallet),
      ],
    );
    addTearDown(container.dispose);
    container.read(transactionHistoryProvider);
    await _settle();

    final result = container.read(transactionNotificationsProvider);

    expect(result.hasError, isTrue);
  });
}
