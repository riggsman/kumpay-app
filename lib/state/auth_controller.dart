import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/phone.dart';
import '../data/auth/auth_models.dart';
import '../data/auth/auth_repository.dart';
import '../data/auth/session_store.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Owns the signed-in session and the in-progress OTP challenge.
///
/// Screens call the methods below and handle the thrown [ApiException]s
/// themselves so they can show the right message for each code.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required SessionStore sessionStore,
    DateTime Function()? clock,
  })  : _repository = repository,
        _sessionStore = sessionStore,
        _clock = clock ?? DateTime.now;

  final AuthRepository _repository;
  final SessionStore _sessionStore;
  final DateTime Function() _clock;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _token;
  String? _pendingPhone;
  DateTime? _resendAvailableAt;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get sessionToken => _token;

  /// Keeps the signed-in profile in step with a contact change.
  void applyContacts({String? phone, String? email}) {
    final current = _user;
    if (current == null) return;
    _user = AppUser(
      id: current.id,
      name: current.name,
      kyc: current.kyc,
      isNewUser: current.isNewUser,
      phone: phone,
      email: email,
      createdAt: current.createdAt,
    );
    notifyListeners();
  }

  void applyKyc(String kyc) {
    final current = _user;
    if (current == null || current.kyc == kyc) return;
    _user = AppUser(
      id: current.id,
      name: current.name,
      kyc: kyc,
      isNewUser: current.isNewUser,
      phone: current.phone,
      email: current.email,
      createdAt: current.createdAt,
    );
    notifyListeners();
  }

  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// E.164 number awaiting a code, if any.
  String? get pendingPhone => _pendingPhone;

  /// How long until the user may request another code.
  Duration get resendWait {
    final at = _resendAvailableAt;
    if (at == null) return Duration.zero;
    final left = at.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// Loads the stored session, if any, and validates it with the server.
  Future<void> restore() async {
    final stored = await _sessionStore.read();
    if (stored == null) {
      _setStatus(AuthStatus.signedOut);
      return;
    }
    try {
      _user = await _repository.me(stored);
      _token = stored;
      _setStatus(AuthStatus.signedIn);
    } on ApiException catch (e) {
      if (e.code == AuthErrorCodes.unauthenticated) {
        await _sessionStore.clear();
      }
      _user = null;
      _token = null;
      _setStatus(AuthStatus.signedOut);
    } catch (_) {
      // Offline or server down: keep the token for the next launch and let
      // the user sign in again if needed.
      _user = null;
      _token = null;
      _setStatus(AuthStatus.signedOut);
    }
  }

  /// Validates [rawPhone] and asks the server to send a code.
  ///
  /// Throws [ApiException] for rule violations (rate limit, delivery failure).
  Future<void> requestOtp(
    String rawPhone, {
    String? name,
    String? email,
  }) async {
    final phone = Phone.normalize(rawPhone);
    if (phone == null) {
      throw const ApiException(
        code: AuthErrorCodes.validation,
        message: 'Enter a valid Cameroon phone number.',
      );
    }
    final challenge = await _repository.requestOtp(
      phone,
      name: name,
      email: email,
    );
    _pendingPhone = challenge.phone;
    _resendAvailableAt =
        _clock().add(Duration(seconds: challenge.resendAfterSec));
    notifyListeners();
  }

  /// Verifies [code] for the pending phone and signs the user in on success.
  ///
  /// Throws [ApiException] (`INVALID_CODE`, `CODE_EXPIRED`, `TOO_MANY_ATTEMPTS`).
  Future<AuthSession> verifyOtp(String code) async {
    final phone = _pendingPhone;
    if (phone == null) {
      throw const ApiException(
        code: AuthErrorCodes.codeExpired,
        message: 'Request a new code to continue.',
      );
    }
    final session = await _repository.verifyOtp(phone: phone, code: code);
    await _sessionStore.write(session.token);
    _token = session.token;
    _user = session.user;
    _pendingPhone = null;
    _resendAvailableAt = null;
    _setStatus(AuthStatus.signedIn);
    return session;
  }

  /// Revokes the session on the server and forgets it locally.
  Future<void> signOut() async {
    final token = _token;
    if (token != null) {
      try {
        await _repository.logout(token);
      } catch (_) {
        // The local session is cleared regardless; the server session expires.
      }
    }
    await _sessionStore.clear();
    _user = null;
    _token = null;
    _pendingPhone = null;
    _resendAvailableAt = null;
    _setStatus(AuthStatus.signedOut);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
