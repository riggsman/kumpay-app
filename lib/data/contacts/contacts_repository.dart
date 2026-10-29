import '../../core/api_client.dart';

class PhoneContact {
  const PhoneContact({
    required this.number,
    required this.verified,
    this.lastChangedAt,
    this.nextEligibleAt,
    this.canChange = true,
    this.remainingDays = 0,
  });

  final String? number;
  final bool verified;
  final String? lastChangedAt;
  final String? nextEligibleAt;
  final bool canChange;
  final int remainingDays;

  static PhoneContact? fromJson(Object? raw, {bool withEligibility = false}) {
    if (raw is! Map) return null;
    final number = raw['number']?.toString();
    if (number == null || number.isEmpty || number == 'null') {
      if (!withEligibility) return null;
    }
    return PhoneContact(
      number: number == null || number.isEmpty || number == 'null' ? null : number,
      verified: raw['verified'] == true,
      lastChangedAt: raw['lastChangedAt']?.toString(),
      nextEligibleAt: raw['nextEligibleAt']?.toString(),
      canChange: raw['canChange'] != false,
      remainingDays: (raw['remainingDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class EmailContact {
  const EmailContact({
    required this.address,
    required this.verified,
    this.lastChangedAt,
  });

  final String? address;
  final bool verified;
  final String? lastChangedAt;

  static EmailContact fromJson(Object? raw) {
    if (raw is! Map) {
      return const EmailContact(address: null, verified: false);
    }
    final address = raw['address']?.toString();
    return EmailContact(
      address: address == null || address.isEmpty || address == 'null' ? null : address,
      verified: raw['verified'] == true,
      lastChangedAt: raw['lastChangedAt']?.toString(),
    );
  }
}

class ContactBook {
  const ContactBook({
    required this.primaryPhone,
    required this.topupPhone,
    required this.email,
  });

  final PhoneContact primaryPhone;
  final PhoneContact? topupPhone;
  final EmailContact email;

  factory ContactBook.fromJson(Map<String, dynamic> json) {
    return ContactBook(
      primaryPhone: PhoneContact.fromJson(json['primaryPhone'], withEligibility: true) ??
          const PhoneContact(number: null, verified: false),
      topupPhone: PhoneContact.fromJson(json['topupPhone']),
      email: EmailContact.fromJson(json['email']),
    );
  }
}

class OtpTicket {
  const OtpTicket({required this.challengeId, required this.expiresInSec});

  final String challengeId;
  final int expiresInSec;

  factory OtpTicket.fromJson(Map<String, dynamic> json) {
    return OtpTicket(
      challengeId: json['challengeId']?.toString() ?? '',
      expiresInSec: (json['expiresInSec'] as num?)?.toInt() ?? 300,
    );
  }
}

/// Client for `/api/me` contact endpoints (CONTACT-1 … CONTACT-14).
class ContactsRepository {
  ContactsRepository({required String baseUrl, required this.token, ApiClient? api})
      : _api = api ?? ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<ContactBook> load() async {
    return ContactBook.fromJson(await _api.get('/api/me/contacts', token: token));
  }

  Future<OtpTicket> requestPhoneChange(String newPhone) async {
    return OtpTicket.fromJson(
      await _api.post('/api/me/phone/change/request', token: token, body: {'newPhone': newPhone}),
    );
  }

  Future<ContactBook> verifyPhoneChange({required String challengeId, required String code}) async {
    return ContactBook.fromJson(
      await _api.post(
        '/api/me/phone/change/verify',
        token: token,
        body: {'challengeId': challengeId, 'code': code},
      ),
    );
  }

  Future<OtpTicket> requestTopupPhone(String number) async {
    return OtpTicket.fromJson(
      await _api.post('/api/me/phone/secondary', token: token, body: {'number': number}),
    );
  }

  Future<ContactBook> verifyTopupPhone({required String challengeId, required String code}) async {
    return ContactBook.fromJson(
      await _api.post(
        '/api/me/phone/secondary/verify',
        token: token,
        body: {'challengeId': challengeId, 'code': code},
      ),
    );
  }

  Future<ContactBook> removeTopupPhone() async {
    return ContactBook.fromJson(await _api.delete('/api/me/phone/secondary', token: token));
  }

  Future<OtpTicket> requestEmailChange(String address) async {
    return OtpTicket.fromJson(
      await _api.post('/api/me/email/change/request', token: token, body: {'address': address}),
    );
  }

  Future<ContactBook> verifyEmailChange({required String challengeId, required String code}) async {
    return ContactBook.fromJson(
      await _api.post(
        '/api/me/email/change/verify',
        token: token,
        body: {'challengeId': challengeId, 'code': code},
      ),
    );
  }

  Future<OtpTicket> requestEmailVerification() async {
    return OtpTicket.fromJson(await _api.post('/api/me/email/verify/request', token: token));
  }

  Future<ContactBook> verifyEmail({required String challengeId, required String code}) async {
    return ContactBook.fromJson(
      await _api.post(
        '/api/me/email/verify',
        token: token,
        body: {'challengeId': challengeId, 'code': code},
      ),
    );
  }
}
