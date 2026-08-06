import '../../data/model/recipient.dart';

/// Domain-level result of submitting a transfer. Lives at the domain layer,
/// not the data layer, because both the repository interface and the
/// provider need to talk about "did it work" independent of how the data
/// arrived (HTTP, cache, mock) — same reasoning as [TopUpResult].
class TransferResult {
  final bool success;
  final String? message;
  final String? reference;

  const TransferResult({required this.success, this.message, this.reference,});
}

/// The contract [TransferNotifier] depends on — never [TransferRepositoryImpl]
/// or the remote data source directly. Same indirection [TopUpRepository]
/// provides: a test can swap in a `FakeTransferRepository` without touching
/// the notifier at all.
abstract class TransferRepository {
  Future<Recipient> getDefaultRecipient();

  /// Returns the list of contacts a user can pick as a transfer recipient.
  /// Matches the backend plan's `GET /api/users/search` in spirit — no
  /// actual query filtering yet, just a fixed list, same scope level as
  /// Top-up's 3 fixed payment methods.
  Future<List<Recipient>> getRecipients();

  Future<TransferResult> submitTransfer({
    required Recipient recipient,
    required double amount,
    required String currency,
    String? note,
  });
}
