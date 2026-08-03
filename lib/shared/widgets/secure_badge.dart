import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// Small reassurance row shown at the bottom of sensitive-action screens
/// (Top-up, Transfer) — a lock icon plus a short label, centered.
///
/// [label] is a parameter rather than hardcoded text because the mockups
/// use slightly different copy per screen ("Secured & encrypted" for
/// Top-up, "Secure & Encrypted" for Transfer) — sharing the icon/layout/
/// style is the point, not forcing identical wording everywhere.
class SecureBadge extends StatelessWidget {
  final String label;

  const SecureBadge({super.key, this.label = 'Secured & encrypted'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}