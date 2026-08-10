import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:fintech_wallet/shared/utils/string_extensions.dart';
import 'package:flutter/material.dart';

/// Displays the transfer recipient: initials avatar, name, email, trailing
/// chevron. The chevron is purely visual for now — Transfer only supports
/// the one fixed mock recipient today (see the conversation's scope
/// decision), so [onTap] has nothing to do yet. Wiring real recipient
/// search/selection later means giving [onTap] a real handler, not
/// changing this widget's layout.
class RecipientCard extends StatelessWidget {
  final Recipient recipient;
  final VoidCallback? onTap;
  final bool showChevron;

  const RecipientCard({
    super.key,
    required this.recipient,
    this.onTap,
    this.showChevron = true,
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
            CircleAvatar(
              radius: 20,
              backgroundColor: recipient.name.avatarColor,
              child: Text(
                recipient.name.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipient.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (recipient.isFrequent)
              Container(
                margin: EdgeInsets.only(right: showChevron ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Frequent',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
