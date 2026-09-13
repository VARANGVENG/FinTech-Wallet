import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/api_endpoints.dart';

class DeviceTokenRemoteDataSource {
  final ApiClient _apiClient;

  DeviceTokenRemoteDataSource(this._apiClient);

  Future<void> register({required String token, required String platform}) {
    return _apiClient.post(
      ApiEndpoints.deviceTokens,
      body: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregister({required String token}) {
    return _apiClient.delete(ApiEndpoints.deviceTokens, body: {'token': token});
  }
}
