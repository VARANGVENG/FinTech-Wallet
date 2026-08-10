import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/topup_result_screen.dart';
import 'package:fintech_wallet/features/topup/presentation/widget/payment_method_tile.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/secure_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/topup_provider.dart';

class ConfirmTopUpScreen extends ConsumerWidget {
  const ConfirmTopUpScreen({super.key});

  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(topUpProvider.notifier);
    final result = await notifier.submit();
    if (!context.mounted) return;

    if (result != null && result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TopUpResultScreen(result: result)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.message ?? 'Something went wrong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topUpProvider);

    PaymentMethod? method;
    for (final m in state.methods) {
      if (m.type == state.selectedMethod) {
        method = m;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Confirm Top-up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (method != null)
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconForPaymentMethod(method.type),
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                method.subtitle,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Amount',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${state.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 8),
                    const DetailRow(label: 'Top-up fee', value: '\$0.00'),
                    DetailRow(
                      label: 'Total to pay',
                      value: '\$${state.amount.toStringAsFixed(2)}',
                    ),
                    const DetailRow(
                      label: 'Arrives',
                      value: 'Instantly',
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Confirm Top-up',
                icon: Icons.lock_outline,
                isLoading: state.submitting,
                onPressed: () => _handleConfirm(context, ref),
              ),
              const SizedBox(height: 12),
              const SecureBadge(),
            ],
          ),
        ),
      ),
    );
  }
}