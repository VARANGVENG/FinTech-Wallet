import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// A single "label ... toggle" row — one per Settings preference (Push
/// Notifications, Transaction Alerts, Biometric Login, Dark Mode). Same
/// "label-left, value-right" shape as `DetailRow`, but worth its own
/// widget rather than reusing it: a `Switch` needs an `onChanged`
/// callback, which `DetailRow` (built for static display, not input) has
/// no concept of.
class SettingsSwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }
}
