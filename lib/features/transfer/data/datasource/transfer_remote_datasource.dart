/// The remote data source is deliberately "dumb": it only knows how to talk
/// to the network and hand back raw JSON-shaped data. It does NOT know about
/// [Recipient] or any other domain model, and it does NOT decide what counts
/// as "success" — that judgment belongs one layer up, in
/// [TransferRepositoryImpl]. Same separation [TopUpRemoteDataSource] follows.
abstract class TransferRemoteDataSource {
  /// Returns raw recipient JSON for the fixed mock recipient.
  Future<Map<String, dynamic>> fetchDefaultRecipient();

  /// Returns the raw JSON response body from the transfer-submission
  /// endpoint. Throws on failure — it does not swallow or wrap errors,
  /// that's the repository's job.
  Future<Map<String, dynamic>> postTransfer({
    required String recipientId,
    required double amount,
    required String currency,
    String? note,
  });
}

/// Thrown by [HttpTransferRemoteDataSource] on network failure. A dedicated
/// exception type means the repository layer only ever needs to catch one
/// thing, regardless of which HTTP client is used underneath.
class TransferNetworkException implements Exception {
  final String message;
  const TransferNetworkException(this.message);

  @override
  String toString() => 'TransferNetworkException: $message';
}

/// Concrete implementation. This is the ONLY class in the whole feature
/// that would import an HTTP client — everything above it works with plain
/// Dart types and never imports one.
class HttpTransferRemoteDataSource implements TransferRemoteDataSource {
  final String baseUrl;

  HttpTransferRemoteDataSource({required this.baseUrl});

  @override
  Future<Map<String, dynamic>> fetchDefaultRecipient() async {
    try {
      // Real version:
      // final res = await client.get(Uri.parse('$baseUrl/users/search?query=...'));
      // if (res.statusCode != 200) {
      //   throw TransferNetworkException('Status ${res.statusCode}');
      // }
      // return jsonDecode(res.body);

      await Future.delayed(const Duration(milliseconds: 300));
      return const {
        'id': 'usr_michael_johnson',
        'name': 'Michael Johnson',
        'email': 'michael.j@email.com',
      };
    } catch (e) {
      throw TransferNetworkException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> postTransfer({
    required String recipientId,
    required double amount,
    required String currency,
    String? note,
  }) async {
    try {
      // Real version:
      // final res = await client.post(
      //   Uri.parse('$baseUrl/transfers'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'recipient_id': recipientId,
      //     'amount': amount,
      //     'currency': currency,
      //     'note': note,
      //   }),
      // );
      // if (res.statusCode != 200) {
      //   throw TransferNetworkException('Status ${res.statusCode}');
      // }
      // return jsonDecode(res.body);

      await Future.delayed(const Duration(milliseconds: 600));
      return const {
        'success': true,
        'message': 'Transfer successful',
        'reference': 'TRF-982475-09',
      };
    } catch (e) {
      throw TransferNetworkException(e.toString());
    }
  }
}