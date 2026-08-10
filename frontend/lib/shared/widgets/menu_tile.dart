import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// A single row in the Profile menu list — title, optional trailing
/// chevron, tappable. [textColor] defaults to the standard text color;
/// Logout overrides it to red and turns off the chevron, since it's an
/// action, not a navigation link like the others.
class MenuTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool showChevron;
  final String? trailing;

  const MenuTile({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
    this.textColor,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (textColor ?? AppColors.textPrimary).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: textColor ?? AppColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
