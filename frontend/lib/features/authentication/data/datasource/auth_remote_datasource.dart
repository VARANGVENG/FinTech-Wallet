import 'package:fintech_wallet/core/network/api_client.dart';
import 'package:fintech_wallet/core/network/api_endpoints.dart';
import '../models/user_model.dart';

/// A login/register response bundles two things the caller needs — the
/// user, and the Bearer token to persist. A record (Dart 3) is the right
/// tool here: it's two related values coming out of one HTTP call, with no
/// identity or behavior of its own — defining a whole `AuthResponse` class
/// just to hold two fields would be exactly the kind of unjustified
/// abstraction we've been avoiding.
typedef AuthResult = ({UserModel user, String token});

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );

    return (
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return (
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get(ApiEndpoints.me);

    return UserModel.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.logout);
  }
}
