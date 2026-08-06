import 'package:fintech_wallet/features/dashboard/presentation/model/transaction_history_model.dart';
import 'package:flutter/material.dart';

enum NotificationCategory { alert, transaction }

/// A single notification — either an "Alert" (payment declined, new
/// device sign-in) or a "Transaction" (derived from transaction history).
/// No Flutter-specific logic beyond the icon, same "plain data" shape
/// every other model in this app follows.
class AppNotification {
  final String id;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final bool isRead;
  final TransactionHistoryModel? transaction;
  final bool isFraudAlert;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    this.isRead = false,
    this.transaction,
    this.isFraudAlert = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      message: message,
      timestamp: timestamp,
      icon: icon,
      isRead: isRead ?? this.isRead,
      transaction: transaction,
      isFraudAlert: isFraudAlert,
    );
  }
}
