import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/dashboard/presentation/model/transaction_history_model.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shows the full detail of a single transaction — reached from a tapped
/// transaction-category notification. Takes the exact same
/// [TransactionHistoryModel] `HomeDashboardScreen`/`WalletScreen` already
/// render, rather than a separate data shape invented just for this screen.
class TransactionDetailScreen extends StatelessWidget {
  final TransactionHistoryModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPending = transaction.status == TransactionStatus.pending;
    final statusText = isPending ? 'Pending' : 'Completed';
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final sign = transaction.isIncome ? '+' : '-';
    final amountText = '$sign\$${transaction.amount.abs().toStringAsFixed(2)}';

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
                child: Icon(transaction.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                transaction.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(
                amountText,
                style: TextStyle(
                  color: transaction.isIncome ? AppColors.success : Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
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
                    DetailRow(label: 'Status', value: statusText, valueColor: statusColor),
                    DetailRow(
                      label: 'Date',
                      value: DateFormat('MMM d, yyyy').format(transaction.transactionDate),
                    ),
                    DetailRow(
                      label: 'Reference ID',
                      value: transaction.id,
                      valueColor: AppColors.accentBlue,
                    ),
                    DetailRow(label: 'Description', value: transaction.description),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Report an Issue',
                onPressed: () {
                  // TODO: wire this up once dispute/fraud reporting exists
                  // — ties back to the deprioritized Fraud Alert feature.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}