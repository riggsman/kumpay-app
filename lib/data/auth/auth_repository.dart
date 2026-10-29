import 'auth_models.dart';

/// Contract for everything the sign-in flow needs from the backend.
///
/// The UI depends only on this interface. Implementations:
/// - [MockAuthRepository]: in-memory, enforces the spec rules. Used until the
///   API is reachable.
/// - an HTTP implementation against `/api/auth/*` (to be added).
///
/// All methods throw [ApiException] for business-rule failures.
abstract interface class AuthRepository {
  /// `POST /api/auth/otp/request`. [phone] is E.164.
  ///
  /// [name] and [email] are stored only when this number creates a new account.
  Future<OtpChallenge> requestOtp(String phone, {String? name, String? email});

  /// `POST /api/auth/otp/verify`. [phone] is E.164.
  ///
  /// Sends the installation snapshot so a successful registration records
  /// the device.
  Future<AuthSession> verifyOtp({required String phone, required String code});

  /// `POST /api/auth/logout`. Revokes [token].
  Future<void> logout(String token);

  /// `GET /api/auth/me`. Throws `UNAUTHENTICATED` if [token] is not valid.
  Future<AppUser> me(String token);
}
