import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

class RecipientSelectPrompt extends StatelessWidget {
  final VoidCallback? onTap;

  const RecipientSelectPrompt({super.key, this.onTap});

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
            const Icon(Icons.person_add_alt, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Select recipient',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
