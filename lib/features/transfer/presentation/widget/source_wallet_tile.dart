import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// Displays the wallet a transfer draws from. Shows a dropdown-style
/// chevron because the mockup implies source selection, but there's only
/// one wallet in this app right now — [onTap] has nothing to switch
/// between yet. Same "visually ready, not yet interactive" approach as
/// `RecipientCard`'s chevron.
class SourceWalletTile extends StatelessWidget {
  final String walletName;
  final double balance;
  final VoidCallback? onTap;

  const SourceWalletTile({
    super.key,
    required this.walletName,
    required this.balance,
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
          border: Border.all(color: AppColors.cardBorder),
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
              child: Text(
                walletName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}