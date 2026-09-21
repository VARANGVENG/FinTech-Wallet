import 'package:fintech_wallet/core/biometrics/data/datasource/biometric_local_datasource.dart';
import 'package:fintech_wallet/core/biometrics/domain/entities/biometric_attempt_result.dart';
import 'package:fintech_wallet/core/biometrics/domain/entities/biometric_capability.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  // mocktail needs a fallback instance for any non-built-in type used with
  // `any(named: ...)` — AuthenticationOptions is such a type. This instance
  // is only ever used as a placeholder, never inspected.
  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  late MockLocalAuthentication localAuth;
  late BiometricLocalDataSource dataSource;

  setUp(() {
    localAuth = MockLocalAuthentication();
    dataSource = BiometricLocalDataSource(localAuth);
  });

  group('checkCapability', () {
    test('returns unsupported when canCheckBiometrics is false', () async {
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);

      expect(await dataSource.checkCapability(), BiometricCapability.unsupported);
    });

    test('returns unsupported when isDeviceSupported is false', () async {
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => false);

      expect(await dataSource.checkCapability(), BiometricCapability.unsupported);
    });

    test('returns notEnrolled when capable but nothing enrolled', () async {
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.getAvailableBiometrics()).thenAnswer((_) async => <BiometricType>[]);

      expect(await dataSource.checkCapability(), BiometricCapability.notEnrolled);
    });

    test('returns available when capable and enrolled', () async {
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.getAvailableBiometrics())
          .thenAnswer((_) async => <BiometricType>[BiometricType.fingerprint]);

      expect(await dataSource.checkCapability(), BiometricCapability.available);
    });

    test('returns unsupported rather than throwing when a call errors', () async {
      when(() => localAuth.canCheckBiometrics).thenThrow(Exception('boom'));

      expect(await dataSource.checkCapability(), BiometricCapability.unsupported);
    });
  });

  group('authenticate', () {
    void stubAuthenticate({
      bool? returns,
      Object? throws,
    }) {
      final call = when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          authMessages: any(named: 'authMessages'),
          options: any(named: 'options'),
        ),
      );
      if (throws != null) {
        call.thenThrow(throws);
      } else {
        call.thenAnswer((_) async => returns!);
      }
    }

    test('returns success when the prompt succeeds', () async {
      stubAuthenticate(returns: true);

      expect(await dataSource.authenticate('reason'), BiometricAttemptResult.success);
    });

    test('returns failed when the prompt completes but fails', () async {
      stubAuthenticate(returns: false);

      expect(await dataSource.authenticate('reason'), BiometricAttemptResult.failed);
    });

    test('passes biometricOnly: true and stickyAuth: true, unchanged from BiometricAuthService', () async {
      stubAuthenticate(returns: true);

      await dataSource.authenticate('Unlock Novapay');

      verify(
        () => localAuth.authenticate(
          localizedReason: 'Unlock Novapay',
          authMessages: any(named: 'authMessages'),
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        ),
      ).called(1);
    });

    for (final code in ['NotEnrolled']) {
      test('maps PlatformException($code) to notEnrolled', () async {
        stubAuthenticate(throws: PlatformException(code: code));
        expect(await dataSource.authenticate('reason'), BiometricAttemptResult.notEnrolled);
      });
    }

    for (final code in ['LockedOut', 'PermanentlyLockedOut']) {
      test('maps PlatformException($code) to lockedOut', () async {
        stubAuthenticate(throws: PlatformException(code: code));
        expect(await dataSource.authenticate('reason'), BiometricAttemptResult.lockedOut);
      });
    }

    for (final code in ['UserCancelled', 'UserFallback']) {
      test('maps PlatformException($code) to cancelled', () async {
        stubAuthenticate(throws: PlatformException(code: code));
        expect(await dataSource.authenticate('reason'), BiometricAttemptResult.cancelled);
      });
    }

    for (final code in [
      'NotAvailable',
      'BiometricNotAvailable',
      'PasscodeNotSet',
      'OtherOperatingSystem',
      'auth_in_progress',
      'no_activity',
      'no_fragment_activity',
    ]) {
      test('maps PlatformException($code) to notAvailable', () async {
        stubAuthenticate(throws: PlatformException(code: code));
        expect(await dataSource.authenticate('reason'), BiometricAttemptResult.notAvailable);
      });
    }

    test('maps an unrecognized PlatformException code to error', () async {
      stubAuthenticate(throws: PlatformException(code: 'something-new'));

      expect(await dataSource.authenticate('reason'), BiometricAttemptResult.error);
    });

    test('maps a non-PlatformException throw (e.g. Windows UnsupportedError) to notAvailable', () async {
      stubAuthenticate(
        throws: UnsupportedError("Windows doesn't support the biometricOnly parameter."),
      );

      expect(await dataSource.authenticate('reason'), BiometricAttemptResult.notAvailable);
    });
  });
}
