import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/api_endpoints.dart';
import '../models/transaction_model.dart';

class TransactionRemoteDataSource {
  final ApiClient _apiClient;

  TransactionRemoteDataSource(this._apiClient);

  Future<List<TransactionModel>> getDefaultWalletTransactions() async {
    final response = await _apiClient.get(
      ApiEndpoints.defaultWalletTransactions,
    );

    final transactions = response['transactions'] as List;
    return transactions
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransactionModel>> getWalletTransactions(String currency) async {
    final response = await _apiClient.get(
      ApiEndpoints.walletTransactions(currency),
    );

    final transactions = response['transactions'] as List;
    return transactions
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
