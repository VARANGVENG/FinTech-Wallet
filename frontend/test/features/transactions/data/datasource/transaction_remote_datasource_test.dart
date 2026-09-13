import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/features/transactions/data/datasource/transaction_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late TransactionRemoteDataSource dataSource;

  setUp(() {
    apiClient = MockApiClient();
    dataSource = TransactionRemoteDataSource(apiClient);
  });

  Map<String, dynamic> transactionJson({int id = 1}) => {
    'id': id,
    'type': 'topup',
    'amount': 10.0,
    'balance_after': 110.0,
    'status': 'completed',
    'description': 'Top-up',
    'related_wallet_id': null,
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  group('getDefaultWalletTransactions', () {
    test('parses transactions and reports hasMore when more pages remain', () async {
      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'transactions': [transactionJson()],
          'meta': {
            'current_page': 1,
            'last_page': 3,
            'per_page': 20,
            'total': 45,
          },
        },
      );

      final page = await dataSource.getDefaultWalletTransactions(page: 1);

      expect(page.transactions, hasLength(1));
      expect(page.transactions.single.id, 1);
      expect(page.hasMore, isTrue);
    });

    test('reports hasMore as false on the last page', () async {
      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'transactions': [transactionJson()],
          'meta': {'current_page': 3, 'last_page': 3},
        },
      );

      final page = await dataSource.getDefaultWalletTransactions(page: 3);

      expect(page.hasMore, isFalse);
    });

    test('defaults hasMore to false when meta is missing', () async {
      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenAnswer((_) async => {'transactions': <dynamic>[]});

      final page = await dataSource.getDefaultWalletTransactions();

      expect(page.transactions, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('requests the given page number', () async {
      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenAnswer((_) async => {'transactions': <dynamic>[]});

      await dataSource.getDefaultWalletTransactions(page: 4);

      verify(
        () => apiClient.get(
          '/wallets/default/transactions',
          query: {'page': 4},
        ),
      ).called(1);
    });
  });

  group('getWalletTransactions', () {
    test('requests the currency-specific endpoint and parses the page', () async {
      when(
        () => apiClient.get(any(), query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'transactions': [transactionJson(id: 2)],
          'meta': {'current_page': 1, 'last_page': 1},
        },
      );

      final page = await dataSource.getWalletTransactions('KHR', page: 1);

      expect(page.transactions.single.id, 2);
      expect(page.hasMore, isFalse);
      verify(
        () => apiClient.get('/wallets/KHR/transactions', query: {'page': 1}),
      ).called(1);
    });
  });
}
