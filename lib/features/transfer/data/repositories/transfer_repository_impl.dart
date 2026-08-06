import '../datasource/transfer_remote_datasource.dart';
import '../model/recipient.dart';
import '../../domain/repositories/transfer_repository.dart';

/// The "business logic" layer. This is where raw JSON becomes real domain
/// objects, and where a failure gets turned into a meaningful [TransferResult]
/// instead of crashing up through the provider — same role
/// [TopUpRepositoryImpl] plays for Top-up.
class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource _remote;

  TransferRepositoryImpl(this._remote);

  @override
  Future<Recipient> getDefaultRecipient() async {
    // Any TransferNetworkException thrown here is intentionally left to
    // propagate — the provider is responsible for catching it and turning
    // it into an "error" UI state, not this layer.
    final json = await _remote.fetchDefaultRecipient();
    return Recipient.fromJson(json);
  }

  @override
  Future<List<Recipient>> getRecipients() async {
    final rawList = await _remote.fetchRecipients();
    return rawList.map((json) => Recipient.fromJson(json)).toList();
  }

  @override
  Future<TransferResult> submitTransfer({
    required Recipient recipient,
    required double amount,
    required String currency,
    String? note,
  }) async {
    final json = await _remote.postTransfer(
      recipientId: recipient.id,
      amount: amount,
      currency: currency,
      note: note,
    );

    // Exactly the kind of translation that belongs at the repository
    // layer: raw JSON keys become a typed, null-safe domain object.
    return TransferResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      reference: json['reference'] as String?,
    );
  }
}
