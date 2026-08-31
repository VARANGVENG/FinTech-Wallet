import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepositoryImpl(WalletRemoteDataSource(apiClient));
});

final walletProvider = FutureProvider<Wallet>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    throw StateError('No authenticated user');
  }

  final repository = ref.watch(walletRepositoryProvider);
  return repository.getDefaultWallet();
});

final walletsProvider = FutureProvider<List<Wallet>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    throw StateError('No authenticated user');
  }

  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWallets();
});
