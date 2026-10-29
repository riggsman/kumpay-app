import 'dart:convert';
import 'dart:math';

import '../../core/api_exception.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

/// In-memory implementation of [AuthRepository] that enforces the server-side
/// rules from the backend spec, so the client's behaviour matches production:
///
/// - AUTH-2: 6-digit code, zero-padded, from a CSPRNG (unless [fixedCode]).
/// - AUTH-3: single use, 5-minute TTL.
/// - AUTH-4: 5 attempts per challenge; then the challenge is burned and the
///   phone is locked for [lockout].
/// - AUTH-5: resend after 60 s, at most 3 resends per hour; a new code
///   invalidates the previous one.
/// - AUTH-6: successful verification issues a session token.
///
/// [fixedCode] exists for development only; never set it in a release build.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    DateTime Function()? clock,
    this.fixedCode,
    Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure() {
    // Seed one existing account so the returning-user path can be exercised.
    _users['usr_aicha'] = const AppUser(
      id: 'usr_aicha',
      name: 'Aïcha Ngono',
      kyc: 'approved',
      isNewUser: false,
    );
    _phoneToUser['+237677123456'] = 'usr_aicha';
  }

  static const otpTtl = Duration(minutes: 5);
  static const resendCooldown = Duration(seconds: 60);
  static const maxResendsPerHour = 3;
  static const maxAttempts = 5;
  static const lockout = Duration(minutes: 15);

  final DateTime Function() _clock;
  final Random _random;
  final String? fixedCode;

  final Map<String, _Challenge> _challengesByPhone = {};
  final Map<String, List<DateTime>> _resendsByPhone = {};
  final Map<String, DateTime> _lockedUntilByPhone = {};
  final Map<String, AppUser> _users = {};
  final Map<String, String> _phoneToUser = {};
  final Map<String, String> _sessions = {};

  @override
  Future<OtpChallenge> requestOtp(
    String phone, {
    String? name,
    String? email,
  }) async {
    final now = _clock();
    _ensureValidPhone(phone);

    final lockedUntil = _lockedUntilByPhone[phone];
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      throw _rateLimited(lockedUntil.difference(now));
    }

    final previous = _challengesByPhone[phone];
    if (previous != null) {
      final sinceLast = now.difference(previous.sentAt);
      if (sinceLast < resendCooldown) {
        throw _rateLimited(resendCooldown - sinceLast);
      }
      final resends = _resendsByPhone.putIfAbsent(phone, () => [])
        ..removeWhere((t) => now.difference(t) >= const Duration(hours: 1));
      if (resends.length >= maxResendsPerHour) {
        final oldest = resends.first;
        throw _rateLimited(const Duration(hours: 1) - now.difference(oldest));
      }
      resends.add(now);
    }

    final challenge = _Challenge(
      id: 'otp_${_token(12)}',
      code: fixedCode ?? _sixDigitCode(),
      sentAt: now,
      expiresAt: now.add(otpTtl),
    );
    // A new code invalidates any previous one for this phone (AUTH-5).
    _challengesByPhone[phone] = challenge;

    return OtpChallenge(
      challengeId: challenge.id,
      phone: phone,
      expiresInSec: otpTtl.inSeconds,
      resendAfterSec: resendCooldown.inSeconds,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final now = _clock();
    _ensureValidPhone(phone);

    final lockedUntil = _lockedUntilByPhone[phone];
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      throw ApiException(
        code: AuthErrorCodes.tooManyAttempts,
        message: 'Too many attempts. Try again later.',
        details: {'retryAfterSec': lockedUntil.difference(now).inSeconds},
      );
    }

    final challenge = _challengesByPhone[phone];
    if (challenge == null ||
        challenge.consumed ||
        !now.isBefore(challenge.expiresAt)) {
      throw const ApiException(
        code: AuthErrorCodes.codeExpired,
        message: 'This code has expired. Request a new one.',
      );
    }

    if (code != challenge.code) {
      challenge.attempts++;
      final remaining = maxAttempts - challenge.attempts;
      if (remaining <= 0) {
        challenge.consumed = true;
        _lockedUntilByPhone[phone] = now.add(lockout);
        throw ApiException(
          code: AuthErrorCodes.tooManyAttempts,
          message: 'Too many attempts. Try again later.',
          details: {'retryAfterSec': lockout.inSeconds},
        );
      }
      throw ApiException(
        code: AuthErrorCodes.invalidCode,
        message: 'Incorrect code.',
        details: {'remainingAttempts': remaining},
      );
    }

    challenge.consumed = true;
    _challengesByPhone.remove(phone);
    _resendsByPhone.remove(phone);

    final isNew = !_phoneToUser.containsKey(phone);
    final user = isNew ? _createUser(phone) : _users[_phoneToUser[phone]!]!;
    final token = _token(32);
    _sessions[token] = user.id;

    return AuthSession(
      token: token,
      deviceCaptured: isNew,
      user: AppUser(
        id: user.id,
        name: user.name,
        kyc: user.kyc,
        isNewUser: isNew,
        phone: phone,
      ),
    );
  }

  @override
  Future<void> logout(String token) async {
    _sessions.remove(token);
  }

  @override
  Future<AppUser> me(String token) async {
    final userId = _sessions[token];
    final user = userId == null ? null : _users[userId];
    if (user == null) {
      throw const ApiException(
        code: AuthErrorCodes.unauthenticated,
        message: 'Your session has ended. Please sign in again.',
      );
    }
    return user;
  }

  AppUser _createUser(String phone) {
    final id = 'usr_${_token(8)}';
    final user =
        AppUser(id: id, name: 'New client', kyc: 'unverified', isNewUser: true);
    _users[id] = user;
    _phoneToUser[phone] = id;
    return user;
  }

  void _ensureValidPhone(String phone) {
    if (!RegExp(r'^\+237[26]\d{8}$').hasMatch(phone)) {
      throw const ApiException(
        code: AuthErrorCodes.validation,
        message: 'Enter a valid Cameroon phone number.',
      );
    }
  }

  ApiException _rateLimited(Duration wait) => ApiException(
        code: AuthErrorCodes.rateLimited,
        message: 'Please wait before requesting another code.',
        details: {'retryAfterSec': wait.inSeconds + 1},
      );

  String _sixDigitCode() {
    final n = _random.nextInt(1000000);
    return n.toString().padLeft(6, '0');
  }

  String _token(int bytes) {
    final data = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64UrlEncode(data).replaceAll('=', '');
  }
}

class _Challenge {
  _Challenge({
    required this.id,
    required this.code,
    required this.sentAt,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final DateTime sentAt;
  final DateTime expiresAt;
  int attempts = 0;
  bool consumed = false;
}
