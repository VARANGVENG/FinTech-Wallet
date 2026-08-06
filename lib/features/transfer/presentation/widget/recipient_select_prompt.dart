import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// Shown on the Transfer screen before a recipient has been picked yet —
/// same tappable card shape as [RecipientCard], but with no recipient data
/// to display, just a prompt. Kept as a separate widget rather than a
/// nullable-recipient mode inside `RecipientCard` itself: the empty state
/// has fundamentally different content (a generic icon + placeholder
/// text, not a name/subtitle/avatar), not just missing data plugged into
/// the same layout.
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