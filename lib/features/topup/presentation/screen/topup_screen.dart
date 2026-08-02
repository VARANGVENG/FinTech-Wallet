import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/presentation/widget/amount_input_card.dart';
import 'package:fintech_wallet/features/topup/presentation/widget/payment_method_tile.dart';
import 'package:fintech_wallet/features/topup/presentation/widget/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/topup_provider.dart';


/// The screen is now a `StatelessWidget`. It no longer owns any mutable
/// state itself (no `_amount`, no `_methods`, no `setState`) — all of that
/// moved into `TopUpProvider`. The screen's only jobs are: (1) trigger the
/// initial load once, and (2) render whatever `TopUpProvider` currently
/// holds. `ChangeNotifierProvider` is placed above this screen (see
/// `main.dart`), so `context.watch<TopUpProvider>()` below can find it.
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  @override
  void initState() {
    super.initState();
    // `listen: false` here because we're only calling a method, not
    // reading data to build the UI with — reading with `listen: true`
    // inside `initState` would throw, since the widget isn't in the tree yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopUpProvider>().loadPaymentMethods();
    });
  }

  Future<void> _handleReviewTopUp(BuildContext context) async {
    final provider = context.read<TopUpProvider>();
    final result = await provider.submit();
    if (!context.mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Reviewing top-up of \$${provider.amount.toStringAsFixed(2)}'
              : result.message ?? 'Something went wrong.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `context.watch` subscribes this widget to `TopUpProvider` — whenever
    // the provider calls `notifyListeners()`, this `build` method re-runs
    // automatically. This one line is the entire replacement for every
    // `setState(() { ... })` call the previous version had.
    final provider = context.watch<TopUpProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text('Top-up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountInputCard(
                amount: provider.amount,
                currency: provider.currency,
                quickAmounts: TopUpProvider.quickAmounts,
                onQuickAmountSelected: provider.selectQuickAmount,
                onCurrencyTap: (_) {},
              ),
              const SizedBox(height: 28),
              const Text(
                'Choose Method',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (provider.loadingMethods)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
                )
              else if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(provider.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: provider.loadPaymentMethods,
                          child: const Text('Retry', style: TextStyle(color: AppColors.accentBlue)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.methods.map(
                  (method) => PaymentMethodTile(
                    method: method,
                    selected: provider.selectedMethod == method.type,
                    onSelect: () => provider.selectMethod(method.type),
                  ),
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Review Top-up',
                isLoading: provider.submitting,
                onPressed: provider.selectedMethod == null ? null : () => _handleReviewTopUp(context),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text('Secured & encrypted', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}