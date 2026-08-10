import 'package:fintech_wallet/app/main_navigation.dart';
import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:fintech_wallet/features/topup/domain/repositories/topup_repository.dart';
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
  final TopUpResult result;

  const TopUpResultScreen({super.key, required this.result});

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

    // Same hardcoded $9,850.20 available-balance figure used everywhere
    // else in this app (Dashboard/Wallet's `CustomCard`) — there's still no
    // real wallet-balance API, so this is the mock starting point the
    // top-up amount gets added to, matching the mockup's $9,850.20 + $100.00
    // = $9,950.20 exactly.
    final newBalance = 9850.20 + state.amount;

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
                '\$${state.amount.toStringAsFixed(2)}',
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
                      value: '\$${newBalance.toStringAsFixed(2)}',
                      valueColor: AppColors.accentBlue,
                    ),
                    DetailRow(
                      label: 'Source',
                      value: method == null ? '—' : '${method.title} ${method.subtitle}',
                    ),
                    DetailRow(
                      label: 'Reference ID',
                      value: result.transactionId ?? '—',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}