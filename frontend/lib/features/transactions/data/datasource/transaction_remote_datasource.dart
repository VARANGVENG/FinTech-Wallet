import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/api_endpoints.dart';
import '../../domain/entities/transaction_page.dart';
import '../models/transaction_model.dart';

class TransactionRemoteDataSource {
  final ApiClient _apiClient;

  TransactionRemoteDataSource(this._apiClient);

  Future<TransactionPage> getDefaultWalletTransactions({int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.defaultWalletTransactions,
      query: {'page': page},
    );
    return _parsePage(response);
  }

  Future<TransactionPage> getWalletTransactions(
    String currency, {
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.walletTransactions(currency),
      query: {'page': page},
    );
    return _parsePage(response);
  }

  TransactionPage _parsePage(Map<String, dynamic> response) {
    final transactions = (response['transactions'] as List)
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // TransactionController::respondWithPage always includes this - current
    // defensively covers an unexpected response shape rather than crashing
    // the whole list over a missing page number.
    final meta = response['meta'] as Map<String, dynamic>?;
    final currentPage = meta?['current_page'] as int? ?? 1;
    final lastPage = meta?['last_page'] as int? ?? 1;

    return TransactionPage(
      transactions: transactions,
      hasMore: currentPage < lastPage,
    );
  }
}
