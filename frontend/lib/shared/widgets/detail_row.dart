import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// A single "label ... value" line — used throughout the Confirm/Result
/// screens for both Top-up and Transfer (e.g. "From" / "NovaPay Wallet",
/// "Date" / "May 29, 2025", "Reference ID" / "TRF-982475-09"). Extracted
/// once both features' mockups turned out to share this exact row shape,
/// rather than duplicating it per feature.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
