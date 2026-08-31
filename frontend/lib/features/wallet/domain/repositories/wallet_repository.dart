import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Wallet> getDefaultWallet();
  Future<List<Wallet>> getWallets();
}
