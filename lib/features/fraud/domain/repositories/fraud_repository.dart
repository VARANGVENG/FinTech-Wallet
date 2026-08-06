import '../../data/model/flagged_transaction.dart';

/// Mirrors the `disputes` table's status lifecycle from the backend plan:
/// `reported` when first flagged, `investigating` if the user says "This
/// wasn't me," `resolved` if they say "It was me."
enum DisputeStatus { reported, investigating, resolved }

/// Domain-level result of responding to a dispute — same "did it work"
/// shape as [TransferResult]/[TopUpResult], independent of how the
/// response actually got there.
class DisputeResult {
  final bool success;
  final DisputeStatus status;
  final String? message;

  const DisputeResult({
    required this.success,
    required this.status,
    this.message,
  });
}

/// The contract [FraudNotifier] depends on. Two response methods, not one
/// generic "respond" call — "This wasn't me" and "It was me" aren't just
/// different parameters to the same operation, they're different backend
/// endpoints with different consequences (`/disputes/{id}/reject` vs
/// `/disputes/{id}/confirm`), so the contract reflects that directly.
abstract class FraudRepository {
  Future<FlaggedTransaction> getFlaggedTransaction();

  /// "This wasn't me" — dispute moves to `investigating`, the underlying
  /// transaction stays on hold.
  Future<DisputeResult> rejectTransaction();

  /// "It was me" — dispute moves to `resolved`, the underlying transaction
  /// becomes `completed`.
  Future<DisputeResult> confirmTransaction();
}
