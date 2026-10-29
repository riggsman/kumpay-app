import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/core/api_exception.dart';
import 'package:kumpay_uiux/data/auth/mock_auth_repository.dart';
import 'package:kumpay_uiux/data/auth/session_store.dart';
import 'package:kumpay_uiux/state/auth_controller.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;
  late MemorySessionStore store;
  late MockAuthRepository repo;

  AuthController newController() => AuthController(
        repository: repo,
        sessionStore: store,
        clock: clock,
      );

  setUp(() {
    now = DateTime.utc(2026, 10, 26, 9);
    store = MemorySessionStore();
    repo = MockAuthRepository(clock: clock, fixedCode: '123456');
  });

  test('restore with no stored token ends signed out', () async {
    final c = newController();
    expect(c.status, AuthStatus.unknown);

    await c.restore();

    expect(c.status, AuthStatus.signedOut);
    expect(c.isSignedIn, isFalse);
  });

  test('requestOtp normalises a national-format number to E.164', () async {
    final c = newController();
    await c.restore();

    await c.requestOtp('677 12 34 56');

    expect(c.pendingPhone, '+237677123456');
    expect(c.resendWait.inSeconds, 60);
  });

  test('requestOtp rejects an invalid number before calling the server',
      () async {
    final c = newController();
    await c.restore();

    await expectLater(
      c.requestOtp('12'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
    );
    expect(c.pendingPhone, isNull);
  });

  test('verifyOtp signs in, stores the token, and survives a restart',
      () async {
    final c = newController();
    await c.restore();
    await c.requestOtp('677123456');

    await c.verifyOtp('123456');

    expect(c.isSignedIn, isTrue);
    expect(c.user?.name, 'Aïcha Ngono');
    expect(c.pendingPhone, isNull);
    expect(await store.read(), isNotNull);

    // A fresh controller (app relaunch) restores the same session.
    final relaunched = newController();
    await relaunched.restore();
    expect(relaunched.isSignedIn, isTrue);
    expect(relaunched.user?.name, 'Aïcha Ngono');
  });

  test('verifyOtp without a pending challenge is refused', () async {
    final c = newController();
    await c.restore();

    await expectLater(
      c.verifyOtp('123456'),
      throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'CODE_EXPIRED')),
    );
    expect(c.isSignedIn, isFalse);
  });

  test('a wrong code leaves the user signed out and the challenge open',
      () async {
    final c = newController();
    await c.restore();
    await c.requestOtp('677123456');

    await expectLater(
      c.verifyOtp('000000'),
      throwsA(
          isA<ApiException>().having((e) => e.remainingAttempts, 'left', 4)),
    );
    expect(c.isSignedIn, isFalse);
    expect(c.pendingPhone, '+237677123456');
  });

  test('signOut clears the stored token and the server session', () async {
    final c = newController();
    await c.restore();
    await c.requestOtp('677123456');
    await c.verifyOtp('123456');

    await c.signOut();

    expect(c.status, AuthStatus.signedOut);
    expect(await store.read(), isNull);

    final relaunched = newController();
    await relaunched.restore();
    expect(relaunched.isSignedIn, isFalse);
  });

  test('a revoked stored token is discarded on restore', () async {
    final c = newController();
    await c.restore();
    await c.requestOtp('677123456');
    await c.verifyOtp('123456');
    // Revoke the session on the server only, leaving the stored token behind.
    await repo.logout((await store.read())!);

    final relaunched = newController();
    await relaunched.restore();

    expect(relaunched.status, AuthStatus.signedOut);
    expect(await store.read(), isNull);
  });
}
