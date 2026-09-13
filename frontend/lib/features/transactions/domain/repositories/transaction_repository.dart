import '../entities/transaction_page.dart';

abstract class TransactionRepository {
  Future<TransactionPage> getDefaultWalletTransactions({int page = 1});
  Future<TransactionPage> getWalletTransactions(String currency, {int page = 1});
}
