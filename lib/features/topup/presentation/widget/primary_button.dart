import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';
// import '../theme/app_colors.dart';

/// Full-width primary call-to-action button.
///
/// Accepts an `isLoading` flag so the *same* widget can show a spinner while
/// the API call is in flight, instead of the screen needing a second,
/// separate "loading button" widget.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        // Disabling onPressed while loading prevents duplicate submissions
        // (e.g. impatient double-tapping firing two API calls).
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          disabledBackgroundColor: AppColors.accentBlue.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}