import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/notifications/data/model/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single row in the Notifications list — icon, title, message,
/// timestamp, and unread dot.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  /// Same convention as CustomTransactionHistoryItem (Wallet screen, Home
  /// dashboard): green for money in, red for money out. Alerts have no
  /// direction (isIncome is null there), so they keep the plain text color.
  Color get _messageColor {
    switch (notification.isIncome) {
      case true:
        return AppColors.income;
      case false:
        return AppColors.expense;
      case null:
        return AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(
                      color: _messageColor,
                      fontWeight: notification.isIncome != null
                          ? FontWeight.bold
                          : FontWeight.normal,
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
          ],
        ),
      ),
    );
  }
}