import 'package:flutter/material.dart';

/// Whether a transaction is still processing or has gone through.
enum TransactionStatus { pending, completed }

class TransactionHistoryModel {
  final String id;
  final String title;
  final String description;
  final DateTime transactionDate;
  final double amount;
  final IconData icon;
  final Color amountColor;
  final bool isIncome;
  final TransactionStatus status;

  const TransactionHistoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.transactionDate,
    required this.amount,
    required this.icon,
    required this.amountColor,
    required this.isIncome,
    this.status = TransactionStatus.completed,
  });
}