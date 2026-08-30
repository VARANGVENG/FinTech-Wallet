import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.balanceAfter,
    required super.status,
    super.description,
    super.relatedWalletId,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: _typeFromJson(json['type']),
      amount: (json['amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      status: _statusFromJson(json['status']),
      description: json['description'],
      relatedWalletId: json['related_wallet_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static TransactionType _typeFromJson(String value) {
    switch (value) {
      case 'topup':
        return TransactionType.topup;
      case 'transfer_in':
        return TransactionType.transferIn;
      case 'transfer_out':
        return TransactionType.transferOut;
      default:
        throw ArgumentError('Unknown transaction type: $value');
    }
  }

  static TransactionStatus _statusFromJson(String value) {
    switch (value) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      default:
        throw ArgumentError('Unknown transaction status: $value');
    }
  }
}