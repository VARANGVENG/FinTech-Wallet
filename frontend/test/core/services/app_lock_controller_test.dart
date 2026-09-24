import 'package:fintech_wallet/core/services/app_lock_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime fakeNow;
  late bool biometricLoginEnabled;
  late bool sessionActive;
  late int lockRequestedCount;
  late AppLockController controller;

  setUp(() {
    fakeNow = DateTime(2026, 1, 1, 12, 0, 0);
    biometricLoginEnabled = true;
    sessionActive = true;
    lockRequestedCount = 0;
    controller = AppLockController(
      isBiometricLoginEnabled: () => biometricLoginEnabled,
      isSessionActive: () => sessionActive,
      onLockRequired: () => lockRequestedCount++,
      now: () => fakeNow,
    );
  });

  void pause() => controller.didChangeAppLifecycleState(AppLifecycleState.paused);
  void resume() => controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
  void advance(Duration d) => fakeNow = fakeNow.add(d);

  group('lock timing', () {
    test('does not lock when backgrounded under 30s', () {
      pause();
      advance(const Duration(seconds: 29));
      resume();

      expect(lockRequestedCount, 0);
    });

    test('locks at exactly 30s', () {
      pause();
      advance(const Duration(seconds: 30));
      resume();

      expect(lockRequestedCount, 1);
    });

    test('locks when backgrounded over 30s', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();

      expect(lockRequestedCount, 1);
    });

    test('does not lock when biometricLogin is disabled', () {
      biometricLoginEnabled = false;
      pause();
      advance(const Duration(minutes: 5));
      resume();

      expect(lockRequestedCount, 0);
    });

    test('does not lock when the session is no longer active', () {
      sessionActive = false;
      pause();
      advance(const Duration(minutes: 5));
      resume();

      expect(lockRequestedCount, 0);
    });

    test('inactive alone does not count as backgrounding', () {
      controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      advance(const Duration(minutes: 5));
      resume();

      expect(lockRequestedCount, 0);
    });

    test('resuming twice in a row without a new pause only locks once', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();
      resume();

      expect(lockRequestedCount, 1);
    });

    test('a second background/resume cycle locks again once the first lock screen is dismissed', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();
      expect(lockRequestedCount, 1);

      controller.onReauthenticated();

      pause();
      advance(const Duration(seconds: 45));
      resume();

      expect(lockRequestedCount, 2);
    });

    test('a qualifying resume before the lock screen is dismissed does not push a duplicate', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();
      expect(lockRequestedCount, 1);

      // Lock screen still up (never dismissed) - a stray extra pause/resume
      // cycle must not request a second one on top of it.
      pause();
      advance(const Duration(seconds: 45));
      resume();

      expect(lockRequestedCount, 1);
    });
  });

  group('navigation gating', () {
    test('runOrDeferWhenUnlocked runs immediately when not locked', () {
      var ran = false;
      controller.runOrDeferWhenUnlocked(() => ran = true);

      expect(ran, isTrue);
    });

    test('runOrDeferWhenUnlocked defers while locked', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();
      expect(controller.isLocked, isTrue);

      var ran = false;
      controller.runOrDeferWhenUnlocked(() => ran = true);

      expect(ran, isFalse);
    });

    test('only the most recent deferred navigation is kept (last-write-wins)', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();

      final calls = <String>[];
      controller.runOrDeferWhenUnlocked(() => calls.add('first'));
      controller.runOrDeferWhenUnlocked(() => calls.add('second'));

      controller.onReauthenticated();

      expect(calls, ['second']);
    });

    test('onReauthenticated replays the deferred navigation exactly once', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();

      var runCount = 0;
      controller.runOrDeferWhenUnlocked(() => runCount++);

      controller.onReauthenticated();
      expect(runCount, 1);

      // Calling it again (e.g. a second, unrelated dismissal) must not
      // replay the same navigation a second time.
      controller.onReauthenticated();
      expect(runCount, 1);
    });

    test('onReauthenticated with nothing deferred is a no-op', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();

      expect(() => controller.onReauthenticated(), returnsNormally);
    });

    test('onLockCleared discards deferred navigation instead of replaying it', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();

      var ran = false;
      controller.runOrDeferWhenUnlocked(() => ran = true);

      controller.onLockCleared();

      expect(ran, isFalse);
    });

    test('onLockCleared resets isLocked so a later resume can lock again', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();
      expect(controller.isLocked, isTrue);

      controller.onLockCleared();
      expect(controller.isLocked, isFalse);

      pause();
      advance(const Duration(seconds: 45));
      resume();

      expect(lockRequestedCount, 2);
    });

    test('deferred navigation is never executed while still locked', () {
      pause();
      advance(const Duration(seconds: 45));
      resume();

      var ran = false;
      controller.runOrDeferWhenUnlocked(() => ran = true);
      // Simulate time passing / other events while still locked - still
      // must not have run.
      expect(ran, isFalse);
      expect(controller.isLocked, isTrue);
    });
  });
}
