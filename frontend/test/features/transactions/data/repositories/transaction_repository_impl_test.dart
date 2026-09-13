import 'package:fintech_wallet/features/transactions/data/datasource/transaction_remote_datasource.dart';
import 'package:fintech_wallet/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}

void main() {
  late MockTransactionRemoteDataSource dataSource;
  late TransactionRepositoryImpl repository;

  setUp(() {
    dataSource = MockTransactionRemoteDataSource();
    repository = TransactionRepositoryImpl(dataSource);
  });

  test('getDefaultWalletTransactions forwards the requested page', () async {
    const expected = TransactionPage(transactions: [], hasMore: true);
    when(
      () => dataSource.getDefaultWalletTransactions(page: 2),
    ).thenAnswer((_) async => expected);

    final result = await repository.getDefaultWalletTransactions(page: 2);

    expect(result, same(expected));
    verify(() => dataSource.getDefaultWalletTransactions(page: 2)).called(1);
  });

  test('getDefaultWalletTransactions defaults to page 1', () async {
    when(
      () => dataSource.getDefaultWalletTransactions(page: 1),
    ).thenAnswer(
      (_) async => const TransactionPage(transactions: [], hasMore: false),
    );

    await repository.getDefaultWalletTransactions();

    verify(() => dataSource.getDefaultWalletTransactions(page: 1)).called(1);
  });

  test('getWalletTransactions forwards the currency and page', () async {
    const expected = TransactionPage(transactions: [], hasMore: false);
    when(
      () => dataSource.getWalletTransactions('KHR', page: 2),
    ).thenAnswer((_) async => expected);

    final result = await repository.getWalletTransactions('KHR', page: 2);

    expect(result, same(expected));
    verify(
      () => dataSource.getWalletTransactions('KHR', page: 2),
    ).called(1);
  });
}
