import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

/// Shown briefly while `main.dart` checks whether a saved auth token
/// exists, before deciding whether to open on `LoginScreen` or
/// `MainNavigation`. Deliberately has no logic of its own — the routing
/// decision lives in exactly one place (`main.dart`), not split across
/// this widget too.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nova Pay',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
