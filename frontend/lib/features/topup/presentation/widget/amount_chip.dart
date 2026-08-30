import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import '../theme/app_colors.dart';

/// A single tappable "$25 / $50 / $100 / $250" pill.
///
/// It's a `StatelessWidget` because it holds no state of its own — the
/// parent (the screen) owns which amount is selected and passes `isSelected`
/// down. This keeps the "source of truth" in one place instead of every
/// chip tracking its own selected flag, which would let them get out of sync.
class AmountChip extends StatelessWidget {
  final double amount;
  final String currencySymbol;
  final bool isSelected;
  final VoidCallback onTap;

  const AmountChip({
    super.key,
    required this.amount,
    required this.currencySymbol,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // GestureDetector rather than ElevatedButton: we want full control
      // over the pill's shape/border without fighting Material's default
      // button padding and ripple styling.
      onTap: onTap,
      child: AnimatedContainer(
        // AnimatedContainer gives a free, smooth color/border transition
        // whenever `isSelected` flips, with no extra AnimationController.
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.accentBlue
                : AppColors.chipUnselectedBorder,
          ),
        ),
        child: Text(
          '$currencySymbol${NumberFormat.decimalPattern().format(amount.toInt())}',
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
