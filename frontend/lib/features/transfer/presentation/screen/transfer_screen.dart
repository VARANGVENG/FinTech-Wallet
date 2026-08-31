import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/confirm_transfer_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/amount_entry_card.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_card.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_picker_sheet.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_select_prompt.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fintech_wallet/shared/widgets/custom_text_field.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/secure_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/transfer_provider.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen>
    with AutomaticKeepAliveClientMixin {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleContinue(BuildContext context) {
    final notifier = ref.read(transferProvider.notifier);
    notifier.setNote(_noteController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConfirmTransferScreen()),
    );
  }

  Future<void> _openRecipientPicker(
    BuildContext context,
    TransferNotifier notifier,
  ) async {
    final selected = await showModalBottomSheet<Recipient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecipientPickerSheet(),
    );
    if (selected != null) {
      notifier.setRecipient(selected);
    }
  }

  Future<void> _handleCurrencyTap(
    BuildContext context,
    List<Wallet> wallets,
    String currentCurrency,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final wallet in wallets)
                ListTile(
                  title: Text(
                    wallet.currency,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: wallet.currency == currentCurrency
                      ? const Icon(Icons.check, color: AppColors.accentBlue)
                      : null,
                  onTap: () => Navigator.pop(context, wallet.currency),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;
    ref.read(transferProvider.notifier).setCurrency(selected);
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(transferProvider);
    final notifier = ref.read(transferProvider.notifier);
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    Wallet? selectedWallet;
    for (final wallet in wallets) {
      if (wallet.currency == state.currency) {
        selectedWallet = wallet;
        break;
      }
    }
    selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
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
              if (state.recipient != null)
                RecipientCard(
                  recipient: state.recipient!,
                  onTap: () => _openRecipientPicker(context, notifier),
                )
              else
                RecipientSelectPrompt(
                  onTap: () => _openRecipientPicker(context, notifier),
                ),
              const SizedBox(height: 24),
              AmountEntryCard(
                controller: _amountController,
                currency: state.currency,
                availableBalance: selectedWallet?.balance ?? 0,
                onAmountChanged: (value) =>
                    notifier.setAmount(double.tryParse(value) ?? 0),
                onCurrencyTap: (current) =>
                    _handleCurrencyTap(context, wallets, current),
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
