import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'device_identity.dart';

/// Talks to the KumPay API (`/api/auth/*`).
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required String baseUrl,
    required DeviceIdentity deviceIdentity,
    ApiClient? api,
  })  : _devices = deviceIdentity,
        _api = api ?? ApiClient(baseUrl: baseUrl);

  final DeviceIdentity _devices;
  final ApiClient _api;

  @override
  Future<OtpChallenge> requestOtp(
    String phone, {
    String? name,
    String? email,
  }) async {
    final body = <String, String>{'phone': phone};
    final cleanName = name?.trim();
    final cleanEmail = email?.trim();
    if (cleanName != null && cleanName.isNotEmpty) body['name'] = cleanName;
    if (cleanEmail != null && cleanEmail.isNotEmpty) body['email'] = cleanEmail;

    final json = await _api.post('/api/auth/otp/request', body: body);
    return OtpChallenge(
      challengeId: '',
      phone: phone,
      expiresInSec: (json['expiresInSec'] as num?)?.toInt() ?? 300,
      resendAfterSec: (json['resendAfterSec'] as num?)?.toInt() ?? 60,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    Map<String, String>? device;
    try {
      device = await _devices.snapshot();
    } catch (_) {
      // The API still records a device from the user agent when this is omitted.
      device = null;
    }
    final json = await _api.post(
      '/api/auth/otp/verify',
      body: {
        'phone': phone,
        'code': code,
        if (device != null) 'device': device,
      },
    );
    final user = json['user'];
    if (user is! Map || json['token'] is! String) {
      throw const ApiException(
        code: AuthErrorCodes.validation,
        message: 'The server returned an unexpected sign-in response.',
      );
    }
    return AuthSession(
      token: json['token'] as String,
      deviceCaptured: json['deviceCaptured'] == true,
      user: AppUser(
        id: user['id']?.toString() ?? '',
        name: user['name']?.toString() ?? 'KumPay client',
        kyc: user['kyc']?.toString() ?? 'unverified',
        isNewUser: json['isNewUser'] == true,
        phone: phone,
        createdAt: _createdAt(user['createdAt']),
      ),
    );
  }

  @override
  Future<void> logout(String token) async {
    await _api.post('/api/auth/logout', token: token);
  }

  @override
  Future<AppUser> me(String token) async {
    final json = await _api.get('/api/auth/me', token: token);
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'KumPay client',
      kyc: json['kyc']?.toString() ?? 'unverified',
      isNewUser: false,
      phone: json['primaryPhone']?.toString(),
      email: json['email']?.toString(),
      createdAt: _createdAt(json['createdAt']),
    );
  }

}

DateTime? _createdAt(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
