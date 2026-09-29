import '../entities/biometric_attempt_result.dart';
import '../entities/biometric_capability.dart';

/// Domain-facing contract for biometric authentication. Implemented by
/// `BiometricRepositoryImpl`, which simply forwards to
/// `BiometricLocalDataSource`. Read directly by `LockScreen` — no separate
/// use-case layer, matching how every other feature in this app calls its
/// repository directly from its provider/notifier.
abstract class BiometricRepository {
  /// Whether this device can currently be prompted for biometrics.
  Future<BiometricCapability> checkCapability();

  /// Prompts the OS biometric UI with [reason] as the user-facing message.
  Future<BiometricAttemptResult> authenticate(String reason);
}
