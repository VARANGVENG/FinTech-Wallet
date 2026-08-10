import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/data/model/payment_method.dart';
import 'package:flutter/material.dart';
// import '../models/payment_method.dart';
// import '../theme/app_colors.dart';

/// Maps a [PaymentMethodType] to a leading icon.
///
/// This lives outside the widget class as a private top-level function
/// because it's a pure lookup with no dependency on widget state — no
/// reason to make it a method that gets rebuilt with the widget.
IconData iconForPaymentMethod(PaymentMethodType type) {
  switch (type) {
    case PaymentMethodType.linkedBank:
      return Icons.account_balance_rounded;
    case PaymentMethodType.debitCard:
      return Icons.credit_card_rounded;
    case PaymentMethodType.applePay:
      return Icons.apple_rounded;
  }
}

/// A single row in the "Choose Method" list: icon, title, subtitle, and a
/// radio circle on the right. Tapping anywhere in the row selects it.
///
/// Kept generic (driven entirely by the [method] + [selected] + [onSelect]
/// params) so the same widget renders every row — the screen just maps over
/// its list of methods instead of hand-writing three near-identical tiles.
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onSelect;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      // Give the whole row a hit target, not just the radio button —
      // matches the screenshot where tapping the row text also selects it.
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accentBlue : AppColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconForPaymentMethod(method.type), color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Custom-painted radio circle instead of `Radio<T>` so it matches
            // the design's filled-dot style exactly, without theming fights.
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
              child: selected
                  ? const Icon(Icons.circle, size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}