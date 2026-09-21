import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/entities/biometric_attempt_result.dart';
import '../../domain/entities/biometric_capability.dart';

/// Wraps `local_auth` directly — the only file in the app that needs to
/// know its platform-specific exception codes. Mirrors
/// `core/services/biometric_auth_service.dart`'s existing shape
/// (constructor-injectable [LocalAuthentication], same
/// `AuthenticationOptions`), but classifies failures instead of collapsing
/// everything to a bool. `BiometricAuthService` itself is untouched and
/// still in use by the app until NOV-007 migrates its callers here.
///
/// Exception mapping verified against the actually-installed
/// `local_auth 2.3.0` / `local_auth_android 1.0.56` /
/// `local_auth_darwin 1.6.1` / `local_auth_windows 1.0.11` source in the
/// pub cache, not assumed from memory or from local_auth's own docs. Two
/// findings from that verification worth keeping in mind if this plugin is
/// ever upgraded:
///
/// - The platform packages currently throw a raw [PlatformException] with
///   a string `code`, matching local_auth's own backward-compatibility
///   TODOs ("Replace this with structured errors..."). The plugin's
///   platform-interface layer already defines a newer, structured
///   `LocalAuthException` type, but no installed platform implementation
///   throws it yet. A future major-version upgrade could switch to it,
///   which would silently fall through to [BiometricAttemptResult.error]
///   here until this mapping is updated.
/// - On Windows, `biometricOnly: true` (used below, matching the existing
///   `BiometricAuthService`) throws a plain [UnsupportedError] —
///   deliberately NOT a [PlatformException] — from
///   `local_auth_windows.dart`. The outer catch-all below exists
///   specifically to classify that case as
///   [BiometricAttemptResult.notAvailable] instead of letting it crash.
class BiometricLocalDataSource {
  BiometricLocalDataSource([LocalAuthentication? localAuth])
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Combines `canCheckBiometrics` (hardware capable, regardless of
  /// enrollment) with `isDeviceSupported()` (hardware capable OR able to
  /// fail over to device credentials) — the same two calls
  /// `BiometricAuthService.isAvailable` already makes, now with
  /// `getAvailableBiometrics()` added on top to distinguish "no hardware"
  /// from "hardware present, nothing enrolled".
  ///
  /// On Windows, `getAvailableBiometrics()` doesn't query real enrollment
  /// state — `local_auth_windows` returns a fixed non-empty list whenever
  /// `isDeviceSupported()` is true, and an empty list otherwise — so
  /// [BiometricCapability.notEnrolled] can never actually be produced on
  /// that platform; only [BiometricCapability.unsupported] or
  /// [BiometricCapability.available].
  Future<BiometricCapability> checkCapability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return BiometricCapability.unsupported;

      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricCapability.notEnrolled
          : BiometricCapability.available;
    } catch (_) {
      return BiometricCapability.unsupported;
    }
  }

  /// Prompts the OS biometric UI. `biometricOnly: true` and
  /// `stickyAuth: true` match `BiometricAuthService.authenticate` exactly —
  /// unchanged behavior, not a new choice made here.
  Future<BiometricAttemptResult> authenticate(String reason) async {
    try {
      final success = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return success
          ? BiometricAttemptResult.success
          : BiometricAttemptResult.failed;
    } on PlatformException catch (e) {
      return _mapPlatformException(e);
    } catch (_) {
      // Covers Windows's UnsupportedError for biometricOnly: true
      // (local_auth_windows.dart), and anything else local_auth might
      // throw that isn't a PlatformException.
      return BiometricAttemptResult.notAvailable;
    }
  }

  /// Codes verified directly against `local_auth_android-1.0.56` and
  /// `local_auth_darwin-1.6.1` source (`error_codes.dart` plus each
  /// platform's own `authenticate()` throw sites) — includes several codes
  /// ('UserCancelled', 'UserFallback', 'BiometricNotAvailable',
  /// 'auth_in_progress', 'no_activity', 'no_fragment_activity') that are
  /// real and stable in the installed source but not part of local_auth's
  /// own public `error_codes.dart` constant list.
  BiometricAttemptResult _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotEnrolled':
        return BiometricAttemptResult.notEnrolled;

      case 'LockedOut': // Android: temporary, 5 fails / 30s
      case 'PermanentlyLockedOut': // Android: needs strong auth to clear
        return BiometricAttemptResult.lockedOut;

      case 'UserCancelled': // Darwin only
      case 'UserFallback': // Darwin only — user tapped "Enter Password"
        return BiometricAttemptResult.cancelled;

      case 'NotAvailable': // Android + Darwin
      case 'BiometricNotAvailable': // Darwin
      case 'PasscodeNotSet': // Darwin
      case 'OtherOperatingSystem': // documented iOS-simulator edge case
      case 'auth_in_progress': // Android: a previous call is still outstanding
      case 'no_activity': // Android: no foreground Activity
      case 'no_fragment_activity': // Android: pre-FlutterFragmentActivity setup issue
        return BiometricAttemptResult.notAvailable;

      default:
        // Includes Pigeon transport-layer failures ('channel-error',
        // 'null-error') common to all three platform packages, and any
        // future/unrecognized code.
        return BiometricAttemptResult.error;
    }
  }
}
