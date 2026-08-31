import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/shared/utils/number_extensions.dart';
import 'package:flutter/material.dart';

class AmountEntryCard extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final double availableBalance;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onCurrencyTap;

  const AmountEntryCard({
    super.key,
    required this.controller,
    required this.currency,
    required this.availableBalance,
    required this.onAmountChanged,
    required this.onCurrencyTap,
  });

  static String _symbolFor(String currency) => currency == 'KHR' ? '៛' : '\$';

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
                'Amount',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              GestureDetector(
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
          TextField(
            controller: controller,
            onChanged: onAmountChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              prefixText: _symbolFor(currency),
              prefixStyle: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Available Balance: ${availableBalance.toCurrency(currencyCode: currency)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
