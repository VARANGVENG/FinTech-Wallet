import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/transfer_result_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/widget/recipient_card.dart';
import 'package:fintech_wallet/shared/widgets/detail_row.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/secure_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/transfer_provider.dart';

/// Screen 2 of the Transfer flow: review everything from `TransferScreen`
/// before actually submitting. `submit()` is finally called here —
/// `TransferScreen`'s "Continue" button only navigates to this screen now,
/// it no longer submits directly.
///
/// `ConsumerWidget`, not `ConsumerStatefulWidget` — this screen has no
/// local widget state or lifecycle needs (no controllers, no `initState`),
/// it's purely reactive to `transferProvider`.
class ConfirmTransferScreen extends ConsumerWidget {
  const ConfirmTransferScreen({super.key});

  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(transferProvider.notifier);
    final result = await notifier.submit();
    if (!context.mounted) return;

    if (result != null && result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TransferResultScreen(result: result)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.message ?? 'Something went wrong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferProvider);
    final recipient = state.recipient;
    final dateLabel = DateFormat('MMM d, yyyy').format(DateTime.now());

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
                  '\$${state.amount.toStringAsFixed(2)}',
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
                    const DetailRow(label: 'From', value: 'NovaPay Wallet'),
                    const DetailRow(
                      label: 'Available Balance',
                      value: '\$3,850.20',
                    ),
                    DetailRow(
                      label: 'Note',
                      value: (state.note != null && state.note!.isNotEmpty)
                          ? state.note!
                          : '—',
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
