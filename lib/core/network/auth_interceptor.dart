import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';


/// A `dio` [Interceptor] runs automatically on every request/response that
/// goes through the shared `Dio` instance — it's how "attach the auth
/// token" and "handle an expired session" get written ONCE, instead of
/// every datasource remembering to add an `Authorization` header by hand.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  /// A callback (rather than a hard navigation call) so this interceptor —
  /// which lives in `core/` and has no knowledge of your app's routes —
  /// doesn't need to import a screen or a `Navigator`. `main.dart` wires
  /// this up to "log the user out and push the sign-in screen."
  final Future<void> Function()? onSessionExpired;

  AuthInterceptor(this._secureStorage, {this.onSessionExpired});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // handler.next(...) passes the (possibly modified) request along the
    // chain — forgetting this call is the #1 bug with Dio interceptors,
    // since the request just hangs forever without it.
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // A 401 means the access token is expired/invalid. Reacting to it here
    // — in one place — means no individual datasource needs its own
    // "check if this failed because of auth" logic.
    if (err.response?.statusCode == 401) {
      await _secureStorage.clearAuthToken();
      if (onSessionExpired != null) {
        await onSessionExpired!();
      }
    }
    handler.next(err);
  }
}