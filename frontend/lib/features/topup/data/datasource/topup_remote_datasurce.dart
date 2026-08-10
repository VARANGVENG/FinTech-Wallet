/// The remote data source is deliberately "dumb": it only knows how to talk
/// to the network and hand back raw JSON-shaped data (`Map`/`List`). It does
/// NOT know about [PaymentMethod] or any other domain model, and it does
/// NOT decide what counts as "success" — that judgment belongs one layer up,
/// in [TopUpRepositoryImpl]. This separation means if the backend switches
/// from REST to GraphQL, or you add a local-cache data source, only this
/// file changes — the repository's business logic is untouched.
abstract class TopUpRemoteDataSource {
  /// Returns raw payment-method JSON objects, straight off the wire.
  Future<List<Map<String, dynamic>>> fetchPaymentMethods();

  /// Returns the raw JSON response body from the top-up submission
  /// endpoint. Throws on non-2xx responses — it does not swallow errors or
  /// wrap them, that's the repository's job.
  Future<Map<String, dynamic>> postTopUp({
    required double amount,
    required String currency,
    required String methodType,
  });
}

/// Thrown by [HttpTopUpRemoteDataSource] on network failure or a non-2xx
/// response. A dedicated exception type (rather than letting raw
/// `http`/`SocketException` leak upward) means the repository layer only
/// ever needs to catch one thing, regardless of which HTTP client is used.
class TopUpNetworkException implements Exception {
  final String message;
  const TopUpNetworkException(this.message);

  @override
  String toString() => 'TopUpNetworkException: $message';
}

/// Concrete implementation. This is the ONLY class in the whole feature
/// that would import `package:http/http.dart` (or `dio`) — everything
/// above it works with plain Dart types and never imports an HTTP package.
class HttpTopUpRemoteDataSource implements TopUpRemoteDataSource {
  final String baseUrl;
  // final http.Client client; // inject your HTTP client here

  HttpTopUpRemoteDataSource({required this.baseUrl});

  @override
  Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
    try {
      // Real version:
      // final res = await client.get(Uri.parse('$baseUrl/payment-methods'));
      // if (res.statusCode != 200) {
      //   throw TopUpNetworkException('Status ${res.statusCode}');
      // }
      // return List<Map<String, dynamic>>.from(jsonDecode(res.body));

      await Future.delayed(const Duration(milliseconds: 400));
      return const [
        {'type': 'linkedBank', 'title': 'Linked Bank', 'subtitle': '•••• 1234', 'iconAsset': 'bank'},
        {'type': 'debitCard', 'title': 'Debit Card', 'subtitle': '•••• 4242', 'iconAsset': 'card'},
        {'type': 'applePay', 'title': 'Apple Pay', 'subtitle': 'Secure & fast', 'iconAsset': 'apple_pay'},
      ];
    } catch (e) {
      // Any lower-level exception (SocketException, TimeoutException, a
      // non-2xx you threw above) is normalized to one exception type here.
      throw TopUpNetworkException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> postTopUp({
    required double amount,
    required String currency,
    required String methodType,
  }) async {
    try {
      // Real version:
      // final res = await client.post(
      //   Uri.parse('$baseUrl/topups'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'amount': amount, 'currency': currency, 'method': methodType}),
      // );
      // if (res.statusCode != 200) {
      //   throw TopUpNetworkException('Status ${res.statusCode}');
      // }
      // return jsonDecode(res.body);

      await Future.delayed(const Duration(milliseconds: 600));
      return const {
        'success': true,
        'message': 'Top-up review created',
        'transactionId': 'txn_demo_123',
      };
    } catch (e) {
      throw TopUpNetworkException(e.toString());
    }
  }
}