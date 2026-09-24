import 'package:fintech_wallet/core/biometrics/domain/entities/biometric_attempt_result.dart';
import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:fintech_wallet/features/authentication/presentation/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _AuthState { authenticating, failed }

/// Full-screen, non-dismissible re-authentication gate shown after the app
/// resumes from being backgrounded past the re-lock threshold (NOV-18) —
/// see `AppLockController`. Unlike `LoginScreen`, the session itself is
/// still valid here: success just pops this screen and returns to
/// whatever was already showing underneath.
///
/// Styling is intentionally minimal (default Material widgets) — visual
/// design wasn't part of NOV-18's approved scope.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onReauthenticated, required this.onLockCleared});

  /// Called once, right before popping, on a successful re-authentication
  /// — lets AppLockController replay any navigation it deferred while
  /// this was up.
  final VoidCallback onReauthenticated;

  /// Called once a forced logout has completed — lets AppLockController
  /// discard (not replay) any deferred navigation, since there's no
  /// authenticated session left to show it in.
  final VoidCallback onLockCleared;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  _AuthState _state = _AuthState.authenticating;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _state = _AuthState.authenticating);

    final result = await ref
        .read(biometricRepositoryProvider)
        .authenticate('Authenticate to continue using Novapay');

    if (!mounted) return;

    switch (result) {
      case BiometricAttemptResult.success:
        // Pop first: onReauthenticated() can synchronously replay a
        // deferred navigation (NOV-18), which pushes a new route and
        // would become the thing `pop()` removes if called after it,
        // leaving this screen never actually dismissed.
        Navigator.of(context).pop();
        widget.onReauthenticated();
      case BiometricAttemptResult.notAvailable:
      case BiometricAttemptResult.notEnrolled:
        // Approved NOV-18 decision: biometrics unavailable mid-session is
        // a forced logout, not a retryable failure — there is nothing to
        // retry, and no bypass or fallback is offered.
        await _logout();
      case BiometricAttemptResult.failed:
      case BiometricAttemptResult.cancelled:
      case BiometricAttemptResult.lockedOut:
      case BiometricAttemptResult.error:
        setState(() => _state = _AuthState.failed);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    // Not gated on `mounted` — this must run even if the widget is
    // somehow gone by the time logout finishes, so AppLockController's
    // state never goes stale relative to reality.
    widget.onLockCleared();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: _state == _AuthState.authenticating
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Authentication required'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _authenticate,
                      child: const Text('Try again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _logout, child: const Text('Log out')),
                  ],
                ),
        ),
      ),
    );
  }
}
