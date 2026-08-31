import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/shared/utils/number_extensions.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shows the full detail of a single transaction — reached from a tapped
/// row in the shared transaction list. Takes the same [Transaction] entity
/// the list renders, rather than a separate data shape invented just for
/// this screen.
class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  final String currencyCode;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.currencyCode = 'USD',
  });

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

  @override
  Widget build(BuildContext context) {
    final isPending = transaction.status == TransactionStatus.pending;
    final statusText = isPending ? 'Pending' : 'Completed';
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final sign = transaction.isIncome ? '+' : '-';
    final amountText =
        '$sign${transaction.amount.toCurrency(currencyCode: currencyCode)}';
    final description = transaction.description ?? 'No description';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Transaction Detail',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  _iconFor(transaction.type),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _titleFor(transaction.type),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                amountText,
                style: TextStyle(
                  color: transaction.isIncome
                      ? AppColors.success
                      : Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    DetailRow(
                      label: 'Status',
                      value: statusText,
                      valueColor: statusColor,
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(
                      label: 'Date',
                      value: DateFormat(
                        'MMM d, yyyy,h:mm a',
                      ).format(transaction.createdAt),
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(
                      label: 'Reference ID',
                      value: '${transaction.id}',
                      valueColor: AppColors.surface,
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(label: 'Description', value: description),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Report an Issue', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
