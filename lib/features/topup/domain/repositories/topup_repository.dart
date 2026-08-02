import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';

// import '../../models/payment_method.dart';

/// Domain-level result of submitting a top-up. Lives at the domain layer
/// (not the data layer) because both the repository interface and the
/// provider need to talk about "did it work", independent of how the data
/// arrived (HTTP, cache, mock).
class TopUpResult {
  final bool success;
  final String? message;
  final String? transactionId;

  const TopUpResult({required this.success, this.message, this.transactionId});
}

/// The contract the rest of the app (specifically [TopUpProvider]) depends
/// on. This is the one file a `TopUpProvider` imports from the data layer —
/// it never imports `TopUpRepositoryImpl` or the remote data source
/// directly. That indirection is what lets a test swap in a
/// `FakeTopUpRepository` without touching the provider at all, and what
/// lets you later add a `CachedTopUpRepository` (repository decorator that
/// checks a local cache before hitting the network) without the provider
/// ever knowing the difference.
abstract class TopUpRepository {
  Future<List<PaymentMethod>> getPaymentMethods();

  Future<TopUpResult> submitTopUp({
    required double amount,
    required String currency,
    required PaymentMethodType method,
  });
}