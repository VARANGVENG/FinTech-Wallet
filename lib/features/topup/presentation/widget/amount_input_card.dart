import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';
// import 'package:fintech_wallet/features/topup/presentation/theme/app_colors.dart';
import 'amount_chip.dart';

/// The card at the top: "Enter Amount", the big dollar figure, currency
/// selector, and the row of quick-amount chips.
///
/// This is pulled out of `TopUpScreen` into its own widget because it's a
/// visually and logically self-contained unit — the screen shouldn't need
/// to know how the amount card lays itself out, only that it needs an
/// `amount`, a `currency`, and callbacks for when either changes.
class AmountInputCard extends StatelessWidget {
  final double amount;
  final String currency;
  final List<double> quickAmounts;
  final TextEditingController controller;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<double> onQuickAmountSelected;
  final ValueChanged<String> onCurrencyTap;

  const AmountInputCard({
    super.key,
    required this.amount,
    required this.currency,
    required this.quickAmounts,
    required this.controller,
    required this.onAmountChanged,
    required this.onQuickAmountSelected,
    required this.onCurrencyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter Amount',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              GestureDetector(
                // Tapping the currency label is where you'd open a
                // currency-picker bottom sheet; wired as a callback so the
                // screen decides what "picking a currency" actually does.
                onTap: () => onCurrencyTap(currency),
                child: Row(
                  children: [
                    Text(
                      currency,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onAmountChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              prefixText: '\$',
              prefixStyle: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Row(
            children: quickAmounts
                .map(
                  (value) => Expanded(
                    child: Padding(
                      // Zero padding on the outer edges keeps the row flush
                      // with the card's own padding, matching the screenshot.
                      padding: EdgeInsets.only(
                        right: value == quickAmounts.last ? 0 : 8,
                      ),
                      child: AmountChip(
                        amount: value,
                        isSelected: amount == value,
                        onTap: () => onQuickAmountSelected(value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
