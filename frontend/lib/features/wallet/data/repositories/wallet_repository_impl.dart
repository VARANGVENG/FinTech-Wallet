import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasource/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl(this.remoteDataSource);

  @override
  Future<Wallet> getDefaultWallet() async {
    return remoteDataSource.getDefaultWallet();
  }

  @override
  Future<List<Wallet>> getWallets() async {
    return remoteDataSource.getWallets();
  }
}
