import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/api_endpoints.dart';
import '../models/wallet_model.dart';

class WalletRemoteDataSource {
  final ApiClient _apiClient;

  WalletRemoteDataSource(this._apiClient);

  Future<WalletModel> getDefaultWallet() async {
    final response = await _apiClient.get(ApiEndpoints.defaultWallet);

    return WalletModel.fromJson(response['wallet'] as Map<String, dynamic>);
  }

  Future<List<WalletModel>> getWallets() async {
    final response = await _apiClient.get(ApiEndpoints.wallets);

    final wallets = response['wallets'] as List;
    return wallets
        .map((json) => WalletModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
