import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/fraud/presentation/provider/fraud_provider.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FraudAlertScreen extends ConsumerStatefulWidget {
  const FraudAlertScreen({super.key});

  @override
  ConsumerState<FraudAlertScreen> createState() => _FraudAlertScreenState();
}

class _FraudAlertScreenState extends ConsumerState<FraudAlertScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fraudProvider.notifier).loadFlaggedTransaction();
    });
  }

  Future<void> _handleReject(BuildContext context) async {
    final result = await ref.read(fraudProvider.notifier).reject();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result?.message ?? 'Something went wrong.')),
    );
    Navigator.pop(context);
  }

  Future<void> _handleConfirm(BuildContext context) async {
    final result = await ref.read(fraudProvider.notifier).confirm();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result?.message ?? 'Something went wrong.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fraudProvider);
    final transaction = state.flaggedTransaction;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: state.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              )
            : state.errorMessage != null
            ? Center(
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.error, width: 2),
                      ),
                      child: const Icon(
                        Icons.priority_high,
                        color: AppColors.error,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Suspicious Transaction',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "We've flagged unusual activity.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (transaction != null)
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
                              label: 'Merchant',
                              value: transaction.merchant,
                            ),
                            DetailRow(
                              label: 'Amount',
                              value:
                                  '\$${transaction.amount.toStringAsFixed(2)}',
                              valueColor: AppColors.error,
                            ),
                            DetailRow(
                              label: 'Date',
                              value: DateFormat(
                                'MMM d, yyyy',
                              ).format(transaction.date),
                            ),
                            DetailRow(
                              label: 'Card',
                              value: '•••• ${transaction.cardLast4}',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Transaction is on hold',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: "This wasn't me",
                      backgroundColor: AppColors.error,
                      isLoading: state.submitting,
                      onPressed: () => _handleReject(context),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: state.submitting
                          ? null
                          : () => _handleConfirm(context),
                      child: const Text(
                        'It was me',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
