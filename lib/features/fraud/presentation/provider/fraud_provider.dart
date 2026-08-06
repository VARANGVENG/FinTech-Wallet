import 'package:fintech_wallet/core/network/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/fraud_remote_datasource.dart';
import '../../data/model/flagged_transaction.dart';
import '../../data/repositories/fraud_repository_impl.dart';
import '../../domain/repositories/fraud_repository.dart';

/// Same shape as `TopUpState`/`TransferState`. No `resolvedStatus` field —
/// `reject()`/`confirm()` return their [DisputeResult] directly to the
/// caller, which navigates away right after, so there's nothing here that
/// needs to persist in reactive state once the action completes.
class FraudState {
  final FlaggedTransaction? flaggedTransaction;
  final bool loading;
  final bool submitting;
  final String? errorMessage;

  const FraudState({
    this.flaggedTransaction,
    this.loading = true,
    this.submitting = false,
    this.errorMessage,
  });

  FraudState copyWith({
    FlaggedTransaction? flaggedTransaction,
    bool? loading,
    bool? submitting,
    String? errorMessage,
  }) {
    return FraudState(
      flaggedTransaction: flaggedTransaction ?? this.flaggedTransaction,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
    );
  }
}

class FraudNotifier extends StateNotifier<FraudState> {
  final FraudRepository _repository;

  FraudNotifier(this._repository) : super(const FraudState());

  Future<void> loadFlaggedTransaction() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final transaction = await _repository.getFlaggedTransaction();
      state = state.copyWith(flaggedTransaction: transaction, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Could not load the flagged transaction.',
      );
    }
  }

  Future<DisputeResult?> reject() async {
    state = state.copyWith(submitting: true);
    try {
      return await _repository.rejectTransaction();
    } catch (e) {
      return const DisputeResult(
        success: false,
        status: DisputeStatus.reported,
        message: 'Something went wrong.',
      );
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<DisputeResult?> confirm() async {
    state = state.copyWith(submitting: true);
    try {
      return await _repository.confirmTransaction();
    } catch (e) {
      return const DisputeResult(
        success: false,
        status: DisputeStatus.reported,
        message: 'Something went wrong.',
      );
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}

final fraudRepositoryProvider = Provider<FraudRepository>((ref) {
  final dataSource = HttpFraudRemoteDataSource(baseUrl: ApiEndpoints.baseUrl);
  return FraudRepositoryImpl(dataSource);
});

final fraudProvider = StateNotifierProvider<FraudNotifier, FraudState>((ref) {
  final repository = ref.watch(fraudRepositoryProvider);
  return FraudNotifier(repository);
});
