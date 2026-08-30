import 'package:fintech_wallet/app/main_navigation.dart';
import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/transactions/domain/entities/transaction.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/result_status_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/topup_provider.dart';

/// Screen 3 of the Top-up flow — shown after `ConfirmTopUpScreen`
/// successfully calls `submit()`. Same shape as `TransferResultScreen`:
/// [result] is a one-time navigation payload, not something `TopUpState`
/// needs to keep carrying around afterward.
class TopUpResultScreen extends ConsumerWidget {
  final Transaction transaction;

  const TopUpResultScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topUpProvider);
    final symbol = TopUpNotifier.symbolFor(state.currency);

    PaymentMethod? method;
    for (final m in state.methods) {
      if (m.type == state.selectedMethod) {
        method = m;
        break;
      }
    }

    final newBalance = transaction.balanceAfter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Top-up Result',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              const ResultStatusHeader(
                title: 'Top-up Successful!',
                subtitle: 'Your money has been added.',
              ),
              const SizedBox(height: 24),
              Text(
                '$symbol${state.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
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
                      label: 'New Balance',
                      value: '$symbol${newBalance.toStringAsFixed(2)}',
                      valueColor: AppColors.accentBlue,
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(
                      label: 'Source',
                      value: method == null
                          ? '—'
                          : '${method.title} ${method.subtitle}',
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(
                      label: 'Reference ID',
                      value: '#${transaction.id}',
                      valueColor: AppColors.accentBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'View Receipt',
                onPressed: () {
                  // TODO: navigate to a real transaction detail/receipt
                  // screen once one exists.
                },
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
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                ),
                child: const Text(
                  'Back to Home',
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
