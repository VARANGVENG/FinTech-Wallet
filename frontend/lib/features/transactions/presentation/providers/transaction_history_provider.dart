import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_page.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRepositoryImpl(TransactionRemoteDataSource(apiClient));
});

class TransactionHistoryState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final StackTrace? stackTrace;

  const TransactionHistoryState({
    this.transactions = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.stackTrace,
  });

  TransactionHistoryState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Infinite-scroll pagination over a transaction-history endpoint - shared
/// by [transactionHistoryProvider] and the per-currency family below, which
/// differ only in which repository method they page through.
class TransactionHistoryNotifier extends StateNotifier<TransactionHistoryState> {
  final Future<TransactionPage> Function(int page) _fetchPage;
  int _nextPage = 1;

  TransactionHistoryNotifier(this._fetchPage)
      : super(const TransactionHistoryState()) {
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    try {
      final page = await _fetchPage(_nextPage);
      _nextPage++;
      state = state.copyWith(
        transactions: page.transactions,
        isLoading: false,
        hasMore: page.hasMore,
      );
    } catch (e, s) {
      state = state.copyWith(isLoading: false, error: e, stackTrace: s);
    }
  }

  /// Fetches the next page and appends it. Safe to call repeatedly (e.g. on
  /// every scroll-position update) - it no-ops while a fetch is already in
  /// flight or there's nothing left to fetch.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _fetchPage(_nextPage);
      _nextPage++;
      state = state.copyWith(
        transactions: [...state.transactions, ...page.transactions],
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      // Leave the already-loaded list intact on a failed "load more" -
      // only isLoadingMore resets, so scrolling back to the bottom lets the
      // user retry instead of losing what's already on screen.
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final transactionHistoryProvider =
    StateNotifierProvider<TransactionHistoryNotifier, TransactionHistoryState>((
      ref,
    ) {
      final authState = ref.watch(authProvider);
      if (authState.user == null) {
        throw StateError('No authenticated user');
      }

      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionHistoryNotifier(
        (page) => repository.getDefaultWalletTransactions(page: page),
      );
    });

final walletTransactionsProvider = StateNotifierProvider.family<
    TransactionHistoryNotifier, TransactionHistoryState, String>((
  ref,
  currency,
) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    throw StateError('No authenticated user');
  }

  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionHistoryNotifier(
    (page) => repository.getWalletTransactions(currency, page: page),
  );
});
