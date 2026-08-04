import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// A single row in the Profile menu list — title, optional trailing
/// chevron, tappable. [textColor] defaults to the standard text color;
/// Logout overrides it to red and turns off the chevron, since it's an
/// action, not a navigation link like the others.
class ProfileMenuTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool showChevron;

  const ProfileMenuTile({
    super.key,
    required this.title,
    this.onTap,
    this.textColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
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
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}