import '../entities/biometric_attempt_result.dart';
import '../entities/biometric_capability.dart';

/// Domain-facing contract for biometric authentication. Implemented by
/// `BiometricRepositoryImpl`, which simply forwards to
/// `BiometricLocalDataSource` — the two methods here mirror exactly what
/// `BiometricAuthService` already exposes (`isAvailable`, `authenticate`),
/// just with richer, source-verified return types in place of a bare bool.
abstract class BiometricRepository {
  /// Whether this device can currently be prompted for biometrics.
  Future<BiometricCapability> checkCapability();

  /// Prompts the OS biometric UI with [reason] as the user-facing message.
  Future<BiometricAttemptResult> authenticate(String reason);
}
