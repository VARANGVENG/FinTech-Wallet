import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fintech_wallet/core/network/auth_interceptor.dart';
import 'package:fintech_wallet/core/storage/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// A minimal [HttpClientAdapter] that always fails with the given status
/// code, without making any real network call. `AuthInterceptor.onError`
/// is exercised through a real [Dio] instance rather than by constructing
/// Dio's internal handler objects directly — those (`ErrorInterceptorHandler`
/// etc.) expose a `@protected future` that only Dio's own package can
/// legitimately await; driving them by hand from a test leaves that
/// completer's error unobserved, which the test runner reports as an
/// unhandled exception. Going through a real `Dio` call lets Dio's own
/// internals (which have that privileged access) do it correctly.
class _FakeFailingAdapter implements HttpClientAdapter {
  _FakeFailingAdapter(this.statusCode);
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: statusCode),
      type: DioExceptionType.badResponse,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWithInterceptor(AuthInterceptor interceptor, int statusCode) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.httpClientAdapter = _FakeFailingAdapter(statusCode);
  dio.interceptors.add(interceptor);
  return dio;
}

void main() {
  late MockSecureStorageService secureStorage;

  setUp(() {
    secureStorage = MockSecureStorageService();
    when(() => secureStorage.clearAuthToken()).thenAnswer((_) async {});
    when(() => secureStorage.getAuthToken()).thenAnswer((_) async => 'token');
  });

  test('a 401 clears the token and calls onSessionExpired', () async {
    var callbackCalled = false;
    final interceptor = AuthInterceptor(
      secureStorage,
      onSessionExpired: () async {
        callbackCalled = true;
      },
    );
    final dio = _dioWithInterceptor(interceptor, 401);

    await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));

    verify(() => secureStorage.clearAuthToken()).called(1);
    expect(callbackCalled, isTrue);
  });

  test('a non-401 error does not clear the token or call onSessionExpired', () async {
    var callbackCalled = false;
    final interceptor = AuthInterceptor(
      secureStorage,
      onSessionExpired: () async {
        callbackCalled = true;
      },
    );
    final dio = _dioWithInterceptor(interceptor, 500);

    await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));

    verifyNever(() => secureStorage.clearAuthToken());
    expect(callbackCalled, isFalse);
  });

  test('the error still propagates to the caller instead of hanging', () async {
    // Regression guard for "the #1 bug with Dio interceptors" the
    // interceptor's own code comment warns about: forgetting handler.next()
    // leaves the request hanging forever instead of surfacing the error.
    // Bounded by a timeout so a regression fails the test, not the suite.
    final interceptor = AuthInterceptor(secureStorage);
    final dio = _dioWithInterceptor(interceptor, 401);

    await expectLater(
      dio.get<void>('/me').timeout(const Duration(seconds: 2)),
      throwsA(isA<DioException>()),
    );
  });
}
