import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/core/api_exception.dart';
import 'package:kumpay_uiux/data/auth/mock_auth_repository.dart';

/// Returns the queued six-digit codes from `nextInt(1000000)`; every other
/// call (token bytes) returns 0.
class _ScriptedRandom implements Random {
  _ScriptedRandom(this.codes);

  final List<int> codes;

  @override
  int nextInt(int max) => max == 1000000 ? codes.removeAt(0) : 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  const phone = '+237677123456';
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime.utc(2026, 10, 26, 9));

  MockAuthRepository repo(List<int> codes) => MockAuthRepository(
        clock: clock,
        random: _ScriptedRandom(codes),
      );

  /// Unwraps the error captured by `.then(..., onError: ...)`.
  ApiException codeOf(Object? e) => e! as ApiException;

  group('OTP request (AUTH-5)', () {
    test('rejects a malformed number with VALIDATION_ERROR', () async {
      final r = repo([1]);
      await expectLater(
        r.requestOtp('+237123'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('blocks a resend inside the 60 s cooldown and reports the wait',
        () async {
      final r = repo([111111, 222222]);
      await r.requestOtp(phone);
      now = now.add(const Duration(seconds: 20));

      final e = codeOf(
          await r.requestOtp(phone).then((_) => null, onError: (e) => e));
      expect(e.code, 'RATE_LIMITED');
      expect(e.retryAfterSec, 41);
    });

    test('allows a resend after the cooldown and caps resends at 3 per hour',
        () async {
      final r = repo([1, 2, 3, 4, 5]);
      await r.requestOtp(phone);
      for (var i = 0; i < 3; i++) {
        now = now.add(const Duration(seconds: 61));
        await r.requestOtp(phone);
      }
      now = now.add(const Duration(seconds: 61));

      final e = codeOf(
          await r.requestOtp(phone).then((_) => null, onError: (e) => e));
      expect(e.code, 'RATE_LIMITED');
    });
  });

  group('OTP verify (AUTH-3, AUTH-4)', () {
    test('a new code invalidates the previous one', () async {
      final r = repo([111111, 222222]);
      await r.requestOtp(phone);
      now = now.add(const Duration(seconds: 61));
      await r.requestOtp(phone);

      final e = codeOf(
        await r
            .verifyOtp(phone: phone, code: '111111')
            .then((_) => null, onError: (e) => e),
      );
      expect(e.code, 'INVALID_CODE');
      expect(e.remainingAttempts, 4);

      final session = await r.verifyOtp(phone: phone, code: '222222');
      expect(session.token, isNotEmpty);
    });

    test('counts down attempts and burns the challenge on the fifth failure',
        () async {
      final r = repo([123456]);
      await r.requestOtp(phone);

      for (var left = 4; left >= 1; left--) {
        final e = codeOf(
          await r
              .verifyOtp(phone: phone, code: '000000')
              .then((_) => null, onError: (e) => e),
        );
        expect(e.code, 'INVALID_CODE');
        expect(e.remainingAttempts, left);
      }
      final burned = codeOf(
        await r
            .verifyOtp(phone: phone, code: '000000')
            .then((_) => null, onError: (e) => e),
      );
      expect(burned.code, 'TOO_MANY_ATTEMPTS');

      // Even the correct code is refused while the phone is locked.
      final locked = codeOf(
        await r
            .verifyOtp(phone: phone, code: '123456')
            .then((_) => null, onError: (e) => e),
      );
      expect(locked.code, 'TOO_MANY_ATTEMPTS');
    });

    test('an expired code is refused with CODE_EXPIRED', () async {
      final r = repo([123456]);
      await r.requestOtp(phone);
      now = now.add(MockAuthRepository.otpTtl);

      final e = codeOf(
        await r
            .verifyOtp(phone: phone, code: '123456')
            .then((_) => null, onError: (e) => e),
      );
      expect(e.code, 'CODE_EXPIRED');
    });

    test('a code is single use', () async {
      final r = repo([123456]);
      await r.requestOtp(phone);
      await r.verifyOtp(phone: phone, code: '123456');

      final e = codeOf(
        await r
            .verifyOtp(phone: phone, code: '123456')
            .then((_) => null, onError: (e) => e),
      );
      expect(e.code, 'CODE_EXPIRED');
    });
  });

  group('sessions (AUTH-6, AUTH-10)', () {
    test('a known number signs in as an existing user, a new number as new',
        () async {
      final r = repo([111111, 222222]);
      await r.requestOtp(phone);
      final existing = await r.verifyOtp(phone: phone, code: '111111');
      expect(existing.user.isNewUser, isFalse);
      expect(existing.user.name, 'Aïcha Ngono');

      const newPhone = '+237699000111';
      await r.requestOtp(newPhone);
      final fresh = await r.verifyOtp(phone: newPhone, code: '222222');
      expect(fresh.user.isNewUser, isTrue);
      expect(fresh.user.kyc, 'unverified');
    });

    test('me() resolves the token; logout revokes it', () async {
      final r = repo([123456]);
      await r.requestOtp(phone);
      final session = await r.verifyOtp(phone: phone, code: '123456');

      expect((await r.me(session.token)).id, session.user.id);

      await r.logout(session.token);
      await expectLater(
        r.me(session.token),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
    });
  });
}
