import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// A single row in the "Select Source" wallet list — icon, name + balance
/// stacked, and a radio circle on the right. Genuinely selectable now
/// that there's more than one wallet — same selectable-row shape as
/// `PaymentMethodTile`, not the old dropdown-chevron placeholder.
class SourceWalletTile extends StatelessWidget {
  final String walletName;
  final double balance;
  final bool selected;
  final VoidCallback? onTap;

  const SourceWalletTile({
    super.key,
    required this.walletName,
    required this.balance,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accentBlue : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    walletName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accentBlue : AppColors.textSecondary,
                  width: 2,
                ),
                color: selected ? AppColors.accentBlue : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.circle, color: Colors.white, size: 8) : null,
            ),
          ],
        ),
      ),
    );
  }
}