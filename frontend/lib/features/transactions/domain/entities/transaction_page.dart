import 'transaction.dart';

/// One page of transaction history, plus whether the backend has another
/// page after this one - drives whether infinite scroll keeps fetching.
class TransactionPage {
  final List<Transaction> transactions;
  final bool hasMore;

  const TransactionPage({required this.transactions, required this.hasMore});
}
