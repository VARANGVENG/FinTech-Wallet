enum TransactionType { topup, transferIn, transferOut }

enum TransactionStatus { pending, completed }

class Transaction {
  final int id;
  final TransactionType type;
  final double amount;
  final double balanceAfter;
  final TransactionStatus status;
  final String? description;
  final int? relatedWalletId;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    this.description,
    this.relatedWalletId,
    required this.createdAt,
  });

  bool get isIncome =>
      type == TransactionType.topup || type == TransactionType.transferIn;
}
