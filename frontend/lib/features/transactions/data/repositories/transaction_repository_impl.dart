import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasource/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Transaction>> getDefaultWalletTransactions() async {
    return remoteDataSource.getDefaultWalletTransactions();
  }

  @override
  Future<List<Transaction>> getWalletTransactions(String currency) async {
    return remoteDataSource.getWalletTransactions(currency);
  }
}
