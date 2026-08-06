/// Deliberately "dumb" — only knows how to talk to the network and hand
/// back raw JSON-shaped data. Doesn't know about [FlaggedTransaction] or
/// [DisputeResult], and doesn't decide what counts as success — that's
/// [FraudRepositoryImpl]'s job. Same separation every other feature's
/// remote data source follows.
abstract class FraudRemoteDataSource {
  Future<Map<String, dynamic>> fetchFlaggedTransaction();
  Future<Map<String, dynamic>> postReject();
  Future<Map<String, dynamic>> postConfirm();
}

/// Thrown on network failure. One dedicated exception type, same reason
/// every other feature's data source has its own.
class FraudNetworkException implements Exception {
  final String message;
  const FraudNetworkException(this.message);

  @override
  String toString() => 'FraudNetworkException: $message';
}

class HttpFraudRemoteDataSource implements FraudRemoteDataSource {
  final String baseUrl;

  HttpFraudRemoteDataSource({required this.baseUrl});

  @override
  Future<Map<String, dynamic>> fetchFlaggedTransaction() async {
    try {
      // Real version:
      // final res = await client.get(Uri.parse('$baseUrl/disputes/{id}'));
      // if (res.statusCode != 200) {
      //   throw FraudNetworkException('Status ${res.statusCode}');
      // }
      // return jsonDecode(res.body);

      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'merchant': 'ElectroMart Online',
        'amount': 1245.00,
        'date': DateTime(2025, 5, 29).toIso8601String(),
        'cardLast4': '4242',
      };
    } catch (e) {
      throw FraudNetworkException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> postReject() async {
    try {
      // Real version:
      // final res = await client.post(Uri.parse('$baseUrl/disputes/{id}/reject'));
      // ...

      await Future.delayed(const Duration(milliseconds: 500));
      return const {
        'success': true,
        'status': 'investigating',
        'message':
            "We've flagged this for investigation and placed a temporary hold on your card.",
      };
    } catch (e) {
      throw FraudNetworkException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> postConfirm() async {
    try {
      // Real version:
      // final res = await client.post(Uri.parse('$baseUrl/disputes/{id}/confirm'));
      // ...

      await Future.delayed(const Duration(milliseconds: 500));
      return const {
        'success': true,
        'status': 'resolved',
        'message': 'Thanks for confirming — the hold has been released.',
      };
    } catch (e) {
      throw FraudNetworkException(e.toString());
    }
  }
}
