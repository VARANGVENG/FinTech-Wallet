import 'package:dio/dio.dart';
import 'package:fintech_wallet/core/errors/api_exception.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

/// The one shared HTTP client for the whole app. Every feature's
/// `XRemoteDataSource` takes an `ApiClient` in its constructor instead of
/// building its own `Dio()` instance — that's what makes the auth header,
/// base URL, timeouts, and logging consistent across every network call in
/// the app, configured in exactly one place.
class ApiClient {
  final Dio _dio;

  ApiClient({required AuthInterceptor authInterceptor})
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(authInterceptor);

    // LogInterceptor is handy in debug builds and dangerous in release
    // ones (it can print tokens/PII to the console) — gate it behind
    // `kDebugMode` in your actual app rather than always-on.
    // _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Every Dio-specific error becomes an ApiException here — this is
      // the ONLY place in the app that ever catches a DioException.
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Translates Dio's various failure types (timeout, no connection, bad
  /// response, cancelled) into one [ApiException] with a message that's
  /// actually useful to show a user — this is where "SocketException:
  /// Failed host lookup" gets turned into something readable.
  ApiException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const ApiException('No internet connection.');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final serverMessage = data is Map ? data['message'] as String? : null;
        return ApiException(
          serverMessage ?? 'Something went wrong.',
          statusCode: e.response?.statusCode,
        );
      default:
        return ApiException(e.message ?? 'Unexpected network error.');
    }
  }
}