import '../../domain/entities/transaction_page.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasource/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<TransactionPage> getDefaultWalletTransactions({int page = 1}) {
    return remoteDataSource.getDefaultWalletTransactions(page: page);
  }

  @override
  Future<TransactionPage> getWalletTransactions(String currency, {int page = 1}) {
    return remoteDataSource.getWalletTransactions(currency, page: page);
  }
}
