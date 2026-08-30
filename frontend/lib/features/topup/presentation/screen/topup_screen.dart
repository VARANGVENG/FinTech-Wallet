import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/confirm_topup_screen.dart';
import 'package:fintech_wallet/features/topup/presentation/widget/amount_input_card.dart';
import 'package:fintech_wallet/features/topup/presentation/widget/payment_method_tile.dart';
import 'package:fintech_wallet/shared/widgets/primary_button.dart';
import 'package:fintech_wallet/shared/widgets/secure_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/topup_provider.dart';

/// `ConsumerStatefulWidget` is Riverpod's stateful widget variant — this
/// screen still owns no mutable state of its own (no `_amount`, no
/// `setState`); all of that lives in `TopUpState`/`TopUpNotifier`.
/// `ref.watch(topUpProvider)` in `build` plays the same role
/// `context.watch<TopUpProvider>()` used to.
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _amountController = TextEditingController(text: '0');
  final _amountFocusNode = FocusNode();

  @override
  void dispose() {
    _amountFocusNode.removeListener(_handleAmountFocusChange);
    _amountFocusNode.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(_handleAmountFocusChange);
    // `ref.read` here, not `ref.watch` — same reasoning as before: this
    // calls a method once, it doesn't need to subscribe this widget to
    // future state changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(topUpProvider.notifier).loadPaymentMethods();
    });
  }

  void _handleAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      if (_amountController.text == '0') {
        _amountController.clear();
      }
    } else if (_amountController.text.isEmpty) {
      final amount = ref.read(topUpProvider).amount;
      _amountController.text = amount == 0 ? '0' : amount.toStringAsFixed(2);
    }
  }

  Future<void> _handleCurrencyTap(
    BuildContext context,
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
              for (final code in const ['USD', 'KHR'])
                ListTile(
                  title: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: code == currentCurrency
                      ? const Icon(Icons.check, color: AppColors.accentBlue)
                      : null,
                  onTap: () => Navigator.pop(context, code),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    ref.read(topUpProvider.notifier).setCurrency(selected);
    _amountController.text = ref.read(topUpProvider).amount.toStringAsFixed(2);
  }

  void _handleReviewTopUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConfirmTopUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `ref.watch` subscribes this widget to `topUpProvider` — whenever
    // `TopUpNotifier` sets a new `state`, this `build` re-runs automatically.
    final state = ref.watch(topUpProvider);
    // `ref.read` for the notifier itself is fine even inside `build` — we're
    // not watching it (it never changes identity), just calling methods on it.
    final notifier = ref.read(topUpProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Top-up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountInputCard(
                amount: state.amount,
                currency: state.currency,
                currencySymbol: TopUpNotifier.symbolFor(state.currency),
                quickAmounts: TopUpNotifier.quickAmountsFor(state.currency),
                controller: _amountController,
                focusNode: _amountFocusNode,
                onAmountChanged: (value) =>
                    notifier.setAmount(double.tryParse(value) ?? 0),
                onQuickAmountSelected: (value) {
                  notifier.setAmount(value);
                  _amountController.text = value.toStringAsFixed(2);
                },
                onCurrencyTap: (current) =>
                    _handleCurrencyTap(context, current),
              ),
              const SizedBox(height: 28),
              const Text(
                'Choose Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (state.loadingMethods)
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
                          onPressed: notifier.loadPaymentMethods,
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: AppColors.accentBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...state.methods.map(
                  (method) => PaymentMethodTile(
                    method: method,
                    selected: state.selectedMethod == method.type,
                    onSelect: () => notifier.selectMethod(method.type),
                  ),
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Review Top-up',
                isLoading: state.submitting,
                onPressed: state.selectedMethod == null
                    ? null
                    : () => _handleReviewTopUp(context),
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
