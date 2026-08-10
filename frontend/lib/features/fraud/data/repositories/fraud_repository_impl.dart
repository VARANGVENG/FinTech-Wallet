import '../datasource/fraud_remote_datasource.dart';
import '../model/flagged_transaction.dart';
import '../../domain/repositories/fraud_repository.dart';

/// Where raw JSON becomes real domain objects, and where a thrown
/// [FraudNetworkException] is left to propagate — the provider catches it
/// and turns it into an "error" UI state, not this layer.
class FraudRepositoryImpl implements FraudRepository {
  final FraudRemoteDataSource _remote;

  FraudRepositoryImpl(this._remote);

  @override
  Future<FlaggedTransaction> getFlaggedTransaction() async {
    final json = await _remote.fetchFlaggedTransaction();
    return FlaggedTransaction(
      merchant: json['merchant'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      cardLast4: json['cardLast4'] as String,
    );
  }

  @override
  Future<DisputeResult> rejectTransaction() async {
    final json = await _remote.postReject();
    return DisputeResult(
      success: json['success'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      message: json['message'] as String?,
    );
  }

  @override
  Future<DisputeResult> confirmTransaction() async {
    final json = await _remote.postConfirm();
    return DisputeResult(
      success: json['success'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      message: json['message'] as String?,
    );
  }

  DisputeStatus _parseStatus(String? raw) {
    return DisputeStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => DisputeStatus.reported,
    );
  }
}
