import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/dashboard/presentation/model/transaction_history_model.dart';
import 'package:flutter/material.dart';

class CustomTransactionHistoryItem extends StatelessWidget {
  final TransactionHistoryModel transaction;

  const CustomTransactionHistoryItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to transaction detail page
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 5),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(transaction.icon, color: AppColors.primary),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          transaction.transactionDate.toString(),
          style: TextStyle(
            color: AppColors.surface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        trailing: Text(
          '\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: transaction.amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
