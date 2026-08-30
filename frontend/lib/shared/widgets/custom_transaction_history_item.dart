import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/features/transactions/presentation/screen/transaction_detail_screen.dart';
import 'package:flutter/material.dart';

class CustomTransactionHistoryItem extends StatelessWidget {
  final Transaction transaction;

  const CustomTransactionHistoryItem({super.key, required this.transaction});

  static const Color _creditColor = Color(0xFF3DDC84);
  static const Color _debitColor = Colors.white;
  static const Color _pendingColor = Color(0xFFE8A33D);
  static const Color _completedColor = Color(0xFF3DDC84);

  static IconData _iconFor(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
        return Icons.add_circle_outline;
      case TransactionType.transferIn:
        return Icons.call_received;
      case TransactionType.transferOut:
        return Icons.call_made;
    }
  }

  static String _titleFor(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
        return 'Top Up';
      case TransactionType.transferIn:
        return 'Transfer In';
      case TransactionType.transferOut:
        return 'Transfer Out';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.isIncome ? _creditColor : _debitColor;
    final sign = transaction.isIncome ? '+' : '-';
    final amountText = '$sign\$${transaction.amount.toStringAsFixed(2)}';

    final isPending = transaction.status == TransactionStatus.pending;
    final statusText = isPending ? 'Pending' : 'Completed';
    final statusColor = isPending ? _pendingColor : _completedColor;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: transaction),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading icon
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(_iconFor(transaction.type), color: AppColors.primary),
            ),
            const SizedBox(width: 14),

            // Title + date (left side)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.description ?? _titleFor(transaction.type),
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(
                    color: AppColors.surface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            // Pushes the left block and right block apart, filling all
            // remaining space regardless of how long title/amount are.
            const Spacer(),

            // Amount + status (right side)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
