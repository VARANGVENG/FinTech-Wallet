import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/dashboard/presentation/model/transaction_history_model.dart';
import 'package:fintech_wallet/features/notifications/data/model/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single row in the Notifications list — icon, title, message,
/// timestamp, unread dot, and (for transaction-category notifications) a
/// highlighted amount on the right, matching `CustomTransactionHistoryItem`'s
/// own sign/color treatment exactly — same colors, same +/- convention.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final transaction = notification.transaction;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(notification.icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.surface,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentBlue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notification.timestamp),
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (transaction != null) ...[
              const SizedBox(width: 12),
              Text(
                '${transaction.isIncome ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: transaction.status == TransactionStatus.pending
                      ? AppColors.warning
                      : (transaction.isIncome
                            ? AppColors.success
                            : AppColors.error),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
