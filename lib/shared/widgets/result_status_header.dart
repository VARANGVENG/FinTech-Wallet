import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// The success-state header shown at the top of a Result screen: a soft
/// circular icon, bold title, and a secondary subtitle underneath. Same
/// shape for Top-up Result ("Top-up Successful!") and Transfer Result
/// ("Transfer Successful!") — only the text differs, so this is one
/// shared widget rather than two near-identical copies.
class ResultStatusHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ResultStatusHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Icon(Icons.check, color: AppColors.success, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}