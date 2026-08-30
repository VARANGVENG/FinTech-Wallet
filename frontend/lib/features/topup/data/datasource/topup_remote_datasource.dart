import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/api_endpoints.dart';
import 'package:fintech_wallet/features/transactions/data/models/transaction_model.dart';
import '../model/payment_method.dart';

class TopUpRemoteDataSource {
  final ApiClient _apiClient;

  TopUpRemoteDataSource(this._apiClient);

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _apiClient.get(ApiEndpoints.paymentMethods);

    final methods = response['methods'] as List;
    return methods
        .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> submitTopUp({
    required double amount,
    required String currency,
    required PaymentMethodType method,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.topups,
      body: {
        'amount': amount,
        'currency': currency,
        'method': method.name,
        'idempotency_key': idempotencyKey,
      },
    );

    return TransactionModel.fromJson(response['transaction'] as Map<String, dynamic>);
  }
}