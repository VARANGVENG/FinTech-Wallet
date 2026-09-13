import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/shared/utils/number_extensions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  /// Null for anything that isn't a monetary in/out event (alerts like
  /// "Payment Declined" have no direction) - true/false only for actual
  /// transaction money movement, so NotificationTile knows when it's even
  /// meaningful to color the amount.
  final bool? isIncome;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    this.isRead = false,
    this.isFraudAlert = false,
    this.isIncome,
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
      isIncome: transaction.isIncome,
    );
  }

  /// Built from a live FCM push (foreground message, or a background/
  /// terminated tap) - the backend sends `type` in the data payload so the
  /// same icon/direction convention as [fromTransaction] can apply here too.
  factory AppNotification.fromPush(RemoteMessage message) {
    final type = message.data['type'] as String?;
    return AppNotification(
      id: message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      category: NotificationCategory.alert,
      title: message.notification?.title ?? 'Notification',
      message: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      icon: _iconForPushType(type),
      isIncome: _isIncomeForPushType(type),
    );
  }

  static IconData _iconForPushType(String? type) {
    switch (type) {
      case 'topup':
        return Icons.add_circle_outline;
      case 'transfer_in':
        return Icons.call_received;
         case 'transfer_out':
        return Icons.call_made;
      default:
        return Icons.notifications_outlined;
    }
  }

  static bool? _isIncomeForPushType(String? type) {
    switch (type) {
      case 'topup':
      case 'transfer_in':
        return true;
      case 'transfer_out':
        return false;
      default:
        return null;
    }
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
      isIncome: isIncome,
    );
  }
}
