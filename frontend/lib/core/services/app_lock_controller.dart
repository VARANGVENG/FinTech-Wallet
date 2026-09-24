import 'package:flutter/widgets.dart';

/// Decides *when* the app should re-lock after being backgrounded
/// (NOV-18) — nothing here knows *how* to lock; that's [onLockRequired]'s
/// job. Kept framework-light (just [WidgetsBindingObserver], no Riverpod)
/// so the lifecycle-transition logic is unit-testable without a
/// ProviderContainer.
class AppLockController with WidgetsBindingObserver {
  AppLockController({
    required this.isBiometricLoginEnabled,
    required this.isSessionActive,
    required this.onLockRequired,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  static const Duration lockThreshold = Duration(seconds: 30);

  final bool Function() isBiometricLoginEnabled;

  /// Whether there's still an authenticated session to protect. Checked
  /// at resume time so a session that expired (or was logged out of)
  /// while backgrounded doesn't get a pointless re-lock prompt pushed on
  /// top of LoginScreen.
  final bool Function() isSessionActive;

  final VoidCallback onLockRequired;
  final DateTime Function() _now;

  DateTime? _backgroundedAt;
  bool _lockScreenShowing = false;
  VoidCallback? _pendingNavigation;

  bool get isLocked => _lockScreenShowing;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // `??=`: an already-recorded pause isn't overwritten by a later one,
      // keeping the earliest (most conservative) timestamp for the check
      // below. `inactive` is deliberately not handled here at all — a
      // transient state (e.g. the app-switcher overview, an incoming
      // call) must not count as backgrounding on its own.
      _backgroundedAt ??= _now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;
    if (_lockScreenShowing) return;
    if (!isBiometricLoginEnabled()) return;
    if (!isSessionActive()) return;

    if (_now().difference(backgroundedAt) >= lockThreshold) {
      _lockScreenShowing = true;
      onLockRequired();
    }
  }

  /// Runs [navigate] immediately if nothing is locked; otherwise defers
  /// it until the lock is resolved. A later call while still locked
  /// overwrites (not queues alongside) any earlier deferred navigation —
  /// only the most recent one is ever kept.
  void runOrDeferWhenUnlocked(VoidCallback navigate) {
    if (_lockScreenShowing) {
      _pendingNavigation = navigate;
    } else {
      navigate();
    }
  }

  /// The lock was cleared by a successful re-authentication — any
  /// navigation deferred by [runOrDeferWhenUnlocked] while locked is now
  /// safe to run, exactly once.
  void onReauthenticated() {
    _lockScreenShowing = false;
    final pending = _pendingNavigation;
    _pendingNavigation = null;
    pending?.call();
  }

  /// The lock is being cleared without a successful re-authentication —
  /// a forced logout, a session expiring elsewhere while locked, or the
  /// lock screen never actually managing to show in the first place (see
  /// main.dart's null-navigator guard). Any deferred navigation is
  /// discarded rather than replayed, since there's no authenticated
  /// session left to show it in.
  void onLockCleared() {
    _lockScreenShowing = false;
    _pendingNavigation = null;
  }
}

/// Set once by main.dart's `_StartupGateState.initState`, once the real
/// AppLockController exists. Lets PushNotificationService (built via a
/// Riverpod provider, with no direct access to widget-tree state) defer
/// its own navigation while a re-lock is pending/active, without this
/// file needing to import PushNotificationService — core_providers.dart
/// already imports push_notification_service.dart to build its provider,
/// so importing back here would be circular. Same reasoning as
/// onSessionExpiredHandler in core_providers.dart.
void Function(VoidCallback navigate) guardNavigation = (navigate) => navigate();
