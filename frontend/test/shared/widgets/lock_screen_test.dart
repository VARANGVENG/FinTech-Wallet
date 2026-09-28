import 'package:fintech_wallet/core/biometrics/domain/entities/biometric_attempt_result.dart';
import 'package:fintech_wallet/core/biometrics/domain/repositories/biometric_repository.dart';
import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/core/services/app_lock_controller.dart';
import 'package:fintech_wallet/core/services/push_notification_service.dart';
import 'package:fintech_wallet/features/authentication/domain/repositories/auth_repository.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:fintech_wallet/features/authentication/presentation/screen/login_screen.dart';
import 'package:fintech_wallet/shared/widgets/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBiometricRepository extends Mock implements BiometricRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPushNotificationService extends Mock implements PushNotificationService {}

void main() {
  late MockBiometricRepository biometricRepository;
  late MockAuthRepository authRepository;
  late MockPushNotificationService pushService;
  late int reauthenticatedCount;
  late int lockClearedCount;

  setUp(() {
    biometricRepository = MockBiometricRepository();
    authRepository = MockAuthRepository();
    pushService = MockPushNotificationService();
    reauthenticatedCount = 0;
    lockClearedCount = 0;
    when(() => authRepository.logout()).thenAnswer((_) async {});
    when(() => pushService.unregisterToken()).thenAnswer((_) async {});
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        biometricRepositoryProvider.overrideWithValue(biometricRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
        pushNotificationServiceProvider.overrideWithValue(pushService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LockScreen(
                      onReauthenticated: () => reauthenticatedCount++,
                      onLockCleared: () => lockClearedCount++,
                    ),
                  ),
                ),
                child: const Text('base screen'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openLockScreen(WidgetTester tester) async {
    // Wide enough that LoginScreen (reached via the forced-logout paths
    // below) doesn't hit its own pre-existing overflow at the default,
    // smaller test viewport - unrelated to NOV-18, not fixed here, see
    // the accompanying report.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('base screen'));
    await tester.pumpAndSettle();
  }

  testWidgets('success calls onReauthenticated, not onLockCleared, and pops the lock screen', (
    tester,
  ) async {
    when(
      () => biometricRepository.authenticate(any()),
    ).thenAnswer((_) async => BiometricAttemptResult.success);

    await openLockScreen(tester);

    expect(find.text('base screen'), findsOneWidget);
    expect(reauthenticatedCount, 1);
    expect(lockClearedCount, 0);
    verifyNever(() => authRepository.logout());
  });

  testWidgets(
    'a failed attempt shows retry and logout, without logging out or calling either callback',
    (tester) async {
      when(
        () => biometricRepository.authenticate(any()),
      ).thenAnswer((_) async => BiometricAttemptResult.failed);

      await openLockScreen(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      verifyNever(() => authRepository.logout());
      expect(reauthenticatedCount, 0);
      expect(lockClearedCount, 0);
    },
  );

  testWidgets(
    'a cancelled attempt shows retry and logout, without logging out or calling either callback',
    (tester) async {
      when(
        () => biometricRepository.authenticate(any()),
      ).thenAnswer((_) async => BiometricAttemptResult.cancelled);

      await openLockScreen(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      verifyNever(() => authRepository.logout());
      expect(reauthenticatedCount, 0);
      expect(lockClearedCount, 0);
    },
  );

  testWidgets('tapping Try again re-attempts authentication', (tester) async {
    var callCount = 0;
    when(() => biometricRepository.authenticate(any())).thenAnswer((_) async {
      callCount++;
      return BiometricAttemptResult.failed;
    });

    await openLockScreen(tester);
    expect(callCount, 1);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });

  testWidgets(
    'tapping Log out after a failed attempt logs out, calls onLockCleared (not onReauthenticated), and shows LoginScreen',
    (tester) async {
      when(
        () => biometricRepository.authenticate(any()),
      ).thenAnswer((_) async => BiometricAttemptResult.failed);

      await openLockScreen(tester);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(() => authRepository.logout()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(lockClearedCount, 1);
      expect(reauthenticatedCount, 0);
    },
  );

  testWidgets(
    'notAvailable forces logout immediately, calling onLockCleared, with no retry offered',
    (tester) async {
      when(
        () => biometricRepository.authenticate(any()),
      ).thenAnswer((_) async => BiometricAttemptResult.notAvailable);

      await openLockScreen(tester);

      verify(() => authRepository.logout()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(lockClearedCount, 1);
      expect(reauthenticatedCount, 0);
    },
  );

  testWidgets(
    'notEnrolled forces logout immediately, calling onLockCleared, with no retry offered',
    (tester) async {
      when(
        () => biometricRepository.authenticate(any()),
      ).thenAnswer((_) async => BiometricAttemptResult.notEnrolled);

      await openLockScreen(tester);

      verify(() => authRepository.logout()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(lockClearedCount, 1);
      expect(reauthenticatedCount, 0);
    },
  );

  testWidgets(
    'regression: success replays a deferred navigation AND actually dismisses LockScreen '
    '(real AppLockController, not fake callbacks - this is the exact interaction the '
    'reorder fix in _authenticate() protects)',
    (tester) async {
      when(
        () => biometricRepository.authenticate(any()),
      ).thenAnswer((_) async => BiometricAttemptResult.success);

      var fakeNow = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = AppLockController(
        isBiometricLoginEnabled: () => true,
        isSessionActive: () => true,
        onLockRequired: () {},
        now: () => fakeNow,
      );

      // Drive the controller into a real locked state through its actual
      // public API - not by poking private fields directly.
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      fakeNow = fakeNow.add(const Duration(seconds: 45));
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.isLocked, isTrue);

      late BuildContext appContext;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [biometricRepositoryProvider.overrideWithValue(biometricRepository)],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                appContext = context;
                return const Scaffold(body: Text('base screen'));
              },
            ),
          ),
        ),
      );

      // A notification tap attempting to navigate while locked - deferred,
      // not executed, exactly as PushNotificationService's guardNavigation
      // call does in production.
      controller.runOrDeferWhenUnlocked(() {
        Navigator.of(appContext).push(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('deferred screen'))),
        );
      });
      expect(find.text('deferred screen'), findsNothing);

      Navigator.of(appContext).push(
        MaterialPageRoute(
          builder: (_) => LockScreen(
            onReauthenticated: controller.onReauthenticated,
            onLockCleared: controller.onLockCleared,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Biometric success must both replay the deferred navigation AND
      // leave LockScreen actually dismissed - not the replayed screen
      // immediately popped back off by a misordered pop().
      expect(find.text('deferred screen'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    },
  );
}
