import 'dart:async';

import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction_page.dart';
import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fintech_wallet/shared/widgets/balance_overview_scaffold.dart';
import 'package:fintech_wallet/shared/widgets/custom_transaction_history_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(int id) => Transaction(
  id: id,
  type: TransactionType.topup,
  amount: 10,
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

Widget _harness(TransactionHistoryNotifier Function(Ref ref) createNotifier) {
  return ProviderScope(
    overrides: [
      transactionHistoryProvider.overrideWith(createNotifier),
      walletProvider.overrideWith((ref) async => _wallet),
    ],
    child: MaterialApp(
      home: BalanceOverviewScaffold(
        headerTitle: 'Test',
        balanceCard: const SizedBox(height: 100),
        quickActions: const [],
        sectionTitle: 'Recent Activity',
      ),
    ),
  );
}

void main() {
  testWidgets('shows a spinner while the first page is loading', (tester) async {
    await tester.pumpWidget(
      _harness((ref) => TransactionHistoryNotifier((_) => Completer<TransactionPage>().future)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an empty state once loaded with no transactions', (tester) async {
    await tester.pumpWidget(
      _harness(
        (ref) => TransactionHistoryNotifier(
          (page) async => const TransactionPage(transactions: [], hasMore: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('shows an error state when the first page fails', (tester) async {
    await tester.pumpWidget(
      _harness(
        (ref) => TransactionHistoryNotifier((page) async => throw Exception('boom')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load transactions"), findsOneWidget);
  });

  testWidgets('renders one item per loaded transaction', (tester) async {
    await tester.pumpWidget(
      _harness(
        (ref) => TransactionHistoryNotifier(
          (page) async => TransactionPage(
            transactions: [_tx(1), _tx(2), _tx(3)],
            hasMore: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomTransactionHistoryItem), findsNWidgets(3));
  });

  testWidgets('scrolling near the bottom loads the next page', (tester) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      _harness((ref) {
        return TransactionHistoryNotifier((page) async {
          requestedPages.add(page);
          // Plenty of items so the list actually overflows the viewport.
          final transactions = List.generate(20, (i) => _tx(page * 100 + i));
          return TransactionPage(transactions: transactions, hasMore: page < 2);
        });
      }),
    );
    await tester.pumpAndSettle();
    expect(requestedPages, [1]);

    // Drag the list up repeatedly to reach its end and cross the
    // load-more threshold.
    for (var i = 0; i < 5; i++) {
      await tester.drag(
        find.byType(CustomTransactionHistoryItem).first,
        const Offset(0, -400),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(requestedPages, [1, 2]);
  });
}
