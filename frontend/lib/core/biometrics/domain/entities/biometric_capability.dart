/// Device-level readiness for biometric authentication, queried via
/// [BiometricRepository.checkCapability] — never persisted, always a live
/// read of the current device state.
///
/// On Windows, [notEnrolled] can never actually be produced: local_auth's
/// Windows implementation doesn't query real enrollment state, it just
/// mirrors device support (`local_auth_windows`'s `getEnrolledBiometrics()`
/// returns a fixed non-empty list whenever `isDeviceSupported()` is true,
/// and an empty list otherwise) — so on Windows this only ever reports
/// [unsupported] or [available].
enum BiometricCapability {
  /// No usable biometric hardware on this device.
  unsupported,

  /// Hardware exists, but nothing is currently enrolled.
  notEnrolled,

  /// Hardware exists and at least one biometric is enrolled — ready to
  /// prompt.
  available,
}
