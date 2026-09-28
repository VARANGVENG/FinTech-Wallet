/// The outcome of one [BiometricRepository.authenticate] call — a
/// transient result, never persisted or held as app-wide state.
///
/// These are application-level buckets, not a re-export of local_auth's
/// platform-specific `PlatformException.code` strings — see
/// `BiometricLocalDataSource` for the exact mapping, verified against the
/// installed local_auth 2.3.0 platform packages' source.
///
/// Platform asymmetry worth knowing: [cancelled] is only ever produced on
/// iOS/macOS (local_auth_darwin throws `UserCancelled`/`UserFallback`);
/// Android has no equivalent signal, and a cancelled prompt there maps to
/// [failed], same as a wrong-finger attempt. Likewise [lockedOut] is
/// Android-only (`LockedOut`/`PermanentlyLockedOut`); Darwin has no
/// lockout-specific error and most likely surfaces as [notAvailable]
/// instead.
enum BiometricAttemptResult {
  /// The user authenticated successfully.
  success,

  /// The challenge was attempted and failed (wrong finger/face), or — on
  /// Android only — the user cancelled, which Android does not
  /// distinguish from a failed match.
  failed,

  /// The user cancelled or chose a fallback option. iOS/macOS only.
  cancelled,

  /// Too many failed attempts; temporarily or permanently locked out.
  /// Android only.
  lockedOut,

  /// Hardware exists but nothing is enrolled.
  notEnrolled,

  /// Biometric authentication could not be attempted at all on this
  /// device/platform right now.
  notAvailable,

  /// An unrecognized or unexpected failure.
  error,
}
