import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/confirm_transfer_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/amount_entry_card.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_card.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/source_wallet_tile.dart';
import 'package:fintech_wallet/shared/widgets/custom_text_field.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/secure_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/transfer_provider.dart';

/// Screen 1 of the Transfer flow (Transfer → Confirm Transfer → Transfer
/// Result). Only this first screen is being built for now — same scope
/// Top-up's own build stopped at.
///
/// Owns `TextEditingController`s for amount/note — a widget-lifecycle
/// concern (`initState`/`dispose`), not app state — while everything else
/// lives in `TransferState`/`TransferNotifier`, same split
/// `LoginScreen`/`RegisterScreen` already use for their controllers.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferProvider.notifier).loadRecipient();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

void _handleContinue(BuildContext context) {
  final notifier = ref.read(transferProvider.notifier);
  // Same reasoning as before: note is only read here, right before moving
  // on, not synced reactively.
  notifier.setNote(_noteController.text.trim());

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ConfirmTransferScreen()),
  );
}

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferProvider);
    final notifier = ref.read(transferProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recipient',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (state.loadingRecipient)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                    ),
                  ),
                )
              else if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: notifier.loadRecipient,
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: AppColors.accentBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state.recipient != null)
                RecipientCard(recipient: state.recipient!, onTap: () {}),
              const SizedBox(height: 24),
              AmountEntryCard(
                controller: _amountController,
                currency: state.currency,
                availableBalance: 3850.20,
                onAmountChanged: (value) =>
                    notifier.setAmount(double.tryParse(value) ?? 0),
                onCurrencyTap: (_) {},
              ),
              const SizedBox(height: 24),
              const Text(
                'Note (optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _noteController,
                hinText: 'Dinner payment',
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Source',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const SourceWalletTile(
                walletName: 'NovaPay Wallet',
                balance: 3850.20,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Continue',
                isLoading: state.submitting,
                onPressed: (state.recipient == null || state.amount <= 0)
                    ? null
                    : () => _handleContinue(context),
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
