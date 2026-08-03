import 'package:fintech_wallet/features/topup/data/datasource/topup_remote_datasurce.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';

import '../../domain/repositories/topup_repository.dart';
// import '../../models/payment_method.dart';
// import '../datasources/topup_remote_data_source.dart';

/// The "business logic" layer. This is where raw JSON becomes real domain
/// objects, and where a failure gets turned into a meaningful [TopUpResult]
/// instead of crashing up through the provider. If you later added a local
/// cache (e.g. show last-known payment methods while offline), that
/// decision would live HERE — not in the data source (which only fetches)
/// and not in the provider (which only manages UI state).
class TopUpRepositoryImpl implements TopUpRepository {
  final TopUpRemoteDataSource _remote;

  TopUpRepositoryImpl(this._remote);

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    // Any TopUpNetworkException thrown here is intentionally left to
    // propagate — the provider is the layer responsible for catching it
    // and turning it into an "error" UI state. The repository's job is
    // just correct data shaping, not deciding how failures are displayed.
    final raw = await _remote.fetchPaymentMethods();
    return raw.map((json) => PaymentMethod.fromJson(json)).toList();
  }

  @override
  Future<TopUpResult> submitTopUp({
    required double amount,
    required String currency,
    required PaymentMethodType method,
  }) async {
    final json = await _remote.postTopUp(
      amount: amount,
      currency: currency,
      methodType: method.name,
    );

    // This is exactly the kind of translation that belongs at the
    // repository layer: the data source's raw JSON keys become a typed,
    // null-safe domain object the rest of the app can rely on.
    return TopUpResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }
}