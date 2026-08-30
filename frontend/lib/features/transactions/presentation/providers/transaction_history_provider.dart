import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRepositoryImpl(TransactionRemoteDataSource(apiClient));
});

final transactionHistoryProvider = FutureProvider<List<Transaction>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    throw StateError('No authenticated user');
  }

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getDefaultWalletTransactions();
});
