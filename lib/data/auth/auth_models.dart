/// Models returned by the auth endpoints (backend spec §1).
class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.phone,
    required this.expiresInSec,
    required this.resendAfterSec,
  });

  final String challengeId;

  /// E.164 phone number the code was sent to.
  final String phone;
  final int expiresInSec;
  final int resendAfterSec;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.kyc,
    required this.isNewUser,
    this.phone,
    this.email,
    this.createdAt,
  });

  final String id;
  final String name;

  /// KYC state: `unverified`, `pending`, `in_progress`, `approved`, `rejected`.
  final String kyc;
  final bool isNewUser;
  final String? phone;
  final String? email;
  final DateTime? createdAt;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.deviceCaptured = false,
  });

  final String token;
  final AppUser user;

  /// True when this sign-in wrote the device row for a new registration.
  final bool deviceCaptured;
}
