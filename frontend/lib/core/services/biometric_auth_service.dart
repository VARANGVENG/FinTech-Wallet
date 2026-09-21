import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` so the rest of the app depends on this
/// interface, not the plugin directly — same reason `PushNotificationService`
/// wraps `firebase_messaging`.
class BiometricAuthService {
  BiometricAuthService([LocalAuthentication? localAuth]) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Whether this device currently has usable biometric hardware with at
  /// least one enrolled credential (Face ID/Touch ID/fingerprint). Both
  /// calls can throw on some platforms/emulators, so treat any failure as
  /// "not available" rather than letting it crash the startup gate.
  Future<bool> get isAvailable async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric UI. Returns false (never throws) on failure,
  /// cancellation, lockout, or an unsupported device — callers only need to
  /// branch on a bool.
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
