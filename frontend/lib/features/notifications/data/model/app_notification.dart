import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/shared/utils/number_extensions.dart';
import 'package:flutter/material.dart';

enum NotificationCategory { alert, transaction }

class AppNotification {
  final String id;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final bool isRead;
  final bool isFraudAlert;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    this.isRead = false,
    this.isFraudAlert = false,
  });

  factory AppNotification.fromTransaction(
    Transaction transaction, {
    final currencyCode = 'USD',
  }) {
    final sign = transaction.isIncome ? '+' : '-';

    return AppNotification(
      id: 'txn-${transaction.id}',
      category: NotificationCategory.transaction,
      title: transaction.description ?? _titleForType(transaction.type),
      message:
          '$sign${transaction.amount.toCurrency(currencyCode: currencyCode)}',
      timestamp: transaction.createdAt,
      icon: _iconForType(transaction.type),
      isRead: true,
    );
  }

  static IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
        return Icons.add_circle_outline;
      case TransactionType.transferIn:
        return Icons.call_received;
      case TransactionType.transferOut:
        return Icons.call_made;
    }
  }

  static String _titleForType(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
        return 'Top Up';
      case TransactionType.transferIn:
        return 'Transfer In';
      case TransactionType.transferOut:
        return 'Transfer Out';
    }
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      message: message,
      timestamp: timestamp,
      icon: icon,
      isRead: isRead ?? this.isRead,
      isFraudAlert: isFraudAlert,
    );
  }
}
