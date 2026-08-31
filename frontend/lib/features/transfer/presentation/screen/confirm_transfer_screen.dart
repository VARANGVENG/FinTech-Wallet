import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/transfer_result_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_card.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fintech_wallet/shared/utils/number_extensions.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/secure_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/transfer_provider.dart';

class ConfirmTransferScreen extends ConsumerWidget {
  const ConfirmTransferScreen({super.key});

  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(transferProvider.notifier);
    final transaction = await notifier.submit();
    if (!context.mounted) return;

    if (transaction != null) {
      ref.invalidate(walletProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(transactionHistoryProvider);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransferResultScreen(transaction: transaction),
        ),
      );
    } else {
      final message =
          ref.read(transferProvider).errorMessage ?? 'Something went wrong.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferProvider);
    final recipient = state.recipient;
    final dateLabel = DateFormat('MMM d, yyyy').format(DateTime.now());
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    Wallet? wallet;
    for (final w in wallets) {
      if (w.currency == state.currency) {
        wallet = w;
        break;
      }
    }
    final currency = state.currency;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Confirm Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipient != null)
                RecipientCard(recipient: recipient, showChevron: false),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  state.amount.toCurrency(currencyCode: currency),
                  style: const TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    DetailRow(
                      label: 'From',
                      value: wallet?.name ?? 'USD Wallet',
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(
                      label: 'Available Balance',
                      value: (wallet?.balance ?? 0).toCurrency(
                        currencyCode: currency,
                      ),
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(
                      label: 'Note',
                      value: (state.note != null && state.note!.isNotEmpty)
                          ? state.note!
                          : '—',
                    ),
                    Divider(
                      color: AppColors.textPrimary,
                      height: 20,
                      thickness: 0.4,
                    ),
                    DetailRow(label: 'Date', value: dateLabel),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Confirm Transfer',
                icon: Icons.lock_outline,
                isLoading: state.submitting,
                onPressed: () => _handleConfirm(context, ref),
              ),
              const SizedBox(height: 12),
              const SecureBadge(label: 'Secure & Encrypted'),
            ],
          ),
        ),
      ),
    );
  }
}
