import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction_page.dart';
import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(int id) => Transaction(
  id: id,
  type: TransactionType.topup,
  amount: 10,
  balanceAfter: 100,
  status: TransactionStatus.completed,
  createdAt: DateTime(2026, 1, 1),
);

/// Lets pending async work (the notifier's own `await`s) actually run,
/// unlike a bare `Future.microtask` which only guarantees one hop.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('TransactionHistoryNotifier', () {
    test('loads the first page on creation', () async {
      final notifier = TransactionHistoryNotifier(
        (page) async => TransactionPage(
          transactions: [_tx(1), _tx(2)],
          hasMore: true,
        ),
      );

      expect(notifier.state.isLoading, isTrue);
      await _settle();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.transactions, hasLength(2));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('surfaces a first-page failure instead of throwing', () async {
      final notifier = TransactionHistoryNotifier(
        (page) async => throw Exception('network down'),
      );

      await _settle();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.transactions, isEmpty);
    });

    test('loadMore appends the next page and advances the page cursor', () async {
      final requestedPages = <int>[];
      final notifier = TransactionHistoryNotifier((page) async {
        requestedPages.add(page);
        if (page == 1) {
          return TransactionPage(transactions: [_tx(1)], hasMore: true);
        }
        return TransactionPage(transactions: [_tx(2)], hasMore: false);
      });
      await _settle();

      await notifier.loadMore();

      expect(requestedPages, [1, 2]);
      expect(notifier.state.transactions.map((t) => t.id), [1, 2]);
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.isLoadingMore, isFalse);
    });

    test('loadMore is a no-op once hasMore is false', () async {
      var callCount = 0;
      final notifier = TransactionHistoryNotifier((page) async {
        callCount++;
        return TransactionPage(transactions: [_tx(page)], hasMore: false);
      });
      await _settle();
      expect(callCount, 1);

      await notifier.loadMore();

      expect(callCount, 1, reason: 'should not fetch again once hasMore is false');
    });

    test('a second loadMore call while one is in flight does not double-fetch', () async {
      var concurrentFetches = 0;
      var maxConcurrentFetches = 0;
      final notifier = TransactionHistoryNotifier((page) async {
        concurrentFetches++;
        maxConcurrentFetches = concurrentFetches > maxConcurrentFetches
            ? concurrentFetches
            : maxConcurrentFetches;
        await Future.delayed(const Duration(milliseconds: 10));
        concurrentFetches--;
        return TransactionPage(transactions: [_tx(page)], hasMore: true);
      });
      await _settle();

      final first = notifier.loadMore();
      final second = notifier.loadMore(); // should see isLoadingMore already true
      await Future.wait([first, second]);

      expect(maxConcurrentFetches, 1);
    });

    test('a failed loadMore keeps existing data and resets isLoadingMore', () async {
      final notifier = TransactionHistoryNotifier((page) async {
        if (page == 2) throw Exception('boom');
        return TransactionPage(transactions: [_tx(1)], hasMore: true);
      });
      await _settle();

      await notifier.loadMore();

      expect(notifier.state.transactions, hasLength(1));
      expect(notifier.state.isLoadingMore, isFalse);
      // hasMore is left untouched on failure, so scrolling back down retries
      // rather than the list silently believing it has reached the end.
      expect(notifier.state.hasMore, isTrue);
    });
  });
}
