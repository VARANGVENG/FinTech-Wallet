import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getDefaultWalletTransactions();
  Future<List<Transaction>> getWalletTransactions(String currency);
}
