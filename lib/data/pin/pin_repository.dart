import '../../core/api_client.dart';

class PinChallenge {
  const PinChallenge({required this.challengeId});

  final String challengeId;

  factory PinChallenge.fromJson(Map<String, dynamic> json) {
    return PinChallenge(challengeId: json['challengeId']?.toString() ?? '');
  }
}

class PinRepository {
  PinRepository({required String baseUrl, required this.token}) : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<PinChallenge> verifyCurrent(String pin) {
    return _api.post('/api/me/pin/verify', token: token, body: {'pin': pin}).then(PinChallenge.fromJson);
  }

  Future<void> change({
    required String challengeId,
    required String code,
    required String newPin,
    required String confirmPin,
  }) {
    return _api.post(
      '/api/me/pin/change',
      token: token,
      body: {
        'challengeId': challengeId,
        'code': code,
        'newPin': newPin,
        'confirmPin': confirmPin,
      },
    );
  }
}
