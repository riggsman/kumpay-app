import 'dart:math';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../features/autopay/autopay_plan.dart';
import '../../features/services/platform_service.dart';
import '../../features/transactions/account_limits.dart';
import '../../features/transactions/transaction_authorizer.dart';
import '../demo.dart';

class MoneyAmount {
  const MoneyAmount({required this.amount, required this.currency});

  final double amount;
  final String currency;

  factory MoneyAmount.fromJson(Object? raw) {
    if (raw is! Map) return const MoneyAmount(amount: 0, currency: 'XAF');
    return MoneyAmount(
      amount: (raw['amount'] as num?)?.toDouble() ?? 0,
      currency: raw['currency']?.toString() ?? 'XAF',
    );
  }

  String get label =>
      currency == 'USD' ? '\$${amount.toStringAsFixed(2)}' : formatXaf(amount);
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.xaf,
    required this.usd,
    required this.phones,
    required this.kyc,
    this.niu,
  });

  final MoneyAmount xaf;
  final MoneyAmount usd;
  final List<({String number, String kind})> phones;
  final String kyc;
  final String? niu;

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) {
    final phones = <({String number, String kind})>[];
    final raw = json['phones'];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          final number = entry['number']?.toString() ?? '';
          if (number.isNotEmpty) {
            phones.add((
              number: number,
              kind: entry['kind']?.toString() ?? 'primary',
            ));
          }
        }
      }
    }
    final niu = json['niu']?.toString();
    return WalletSnapshot(
      xaf: MoneyAmount.fromJson(json['xaf']),
      usd: MoneyAmount.fromJson(json['usd']),
      phones: phones,
      kyc: json['kyc']?.toString() ?? 'unverified',
      niu: niu == null || niu.isEmpty || niu == 'null' ? null : niu,
    );
  }
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.incoming,
    required this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final MoneyAmount amount;
  final bool incoming;
  final String kind;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      amount: MoneyAmount.fromJson(json['amount']),
      incoming: json['incoming'] == true,
      kind: json['kind']?.toString() ?? '',
    );
  }
}

class ActivityBook {
  const ActivityBook({
    required this.items,
    required this.moneyInXaf,
    required this.moneyOutXaf,
  });

  final List<ActivityItem> items;
  final double moneyInXaf;
  final double moneyOutXaf;

  factory ActivityBook.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return ActivityBook(
      items: [
        if (raw is List)
          for (final entry in raw)
            if (entry is Map)
              ActivityItem.fromJson(
                entry.map((key, value) => MapEntry(key.toString(), value)),
              ),
      ],
      moneyInXaf: (json['moneyInXaf'] as num?)?.toDouble() ?? 0,
      moneyOutXaf: (json['moneyOutXaf'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TransferResult {
  const TransferResult({
    required this.reference,
    required this.recipientName,
    required this.phone,
    required this.amount,
    required this.createdAt,
  });

  final String reference;
  final String recipientName;
  final String phone;
  final MoneyAmount amount;
  final String? createdAt;

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      reference: json['reference']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      amount: MoneyAmount.fromJson(json['amount']),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class FeeInstitution {
  const FeeInstitution({required this.code, required this.name});

  final String code;
  final String name;

  factory FeeInstitution.fromJson(Map<String, dynamic> json) {
    return FeeInstitution(
      code: json['code']?.toString() ?? '',
      name: json['displayName']?.toString() ??
          json['legalName']?.toString() ??
          '',
    );
  }
}

class FeeOption {
  const FeeOption({
    required this.periodId,
    required this.categoryCode,
    required this.label,
    required this.amount,
  });

  final String periodId;
  final String categoryCode;
  final String label;
  final MoneyAmount amount;

  factory FeeOption.fromJson(Map<String, dynamic> json) {
    return FeeOption(
      periodId: json['academicPeriodId']?.toString() ?? '',
      categoryCode: json['feeCategory']?.toString() ?? '',
      label:
          '${json['feeCategoryName'] ?? json['feeCategory'] ?? 'Fee'} · ${json['academicPeriod'] ?? ''}'
              .trim(),
      amount: MoneyAmount.fromJson(json['amount']),
    );
  }
}

class AccountDevice {
  const AccountDevice({
    required this.model,
    required this.platform,
    required this.lastSeenAt,
  });

  final String model;
  final String platform;
  final String? lastSeenAt;

  factory AccountDevice.fromJson(Map<String, dynamic> json) {
    final model = json['model']?.toString();
    return AccountDevice(
      model: model == null || model.isEmpty || model == 'null'
          ? (json['platform']?.toString() ?? 'Device')
          : model,
      platform: json['platform']?.toString() ?? '',
      lastSeenAt: json['lastSeenAt']?.toString(),
    );
  }
}

class MoneyRepository {
  MoneyRepository({
    required String baseUrl,
    required this.token,
    ApiClient? api,
    TransactionAuthorizer? authorizer,
  })  : _api = api ?? ApiClient(baseUrl: baseUrl),
        _authorizer = authorizer ?? TransactionAuthorizer(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;
  final TransactionAuthorizer _authorizer;

  /// Confirms the platform still allows this movement, then lets the caller post it.
  Future<void> _guard({
    required TransactionKind kind,
    required double amount,
    required String currency,
    String? biller,
    String? kyc,
    bool featureEnabled = true,
    String? mfaCode,
    String? challengeId,
    AccountLimits? knownLimits,
  }) async {
    var limits = knownLimits;
    if (limits == null) {
      try {
        limits = await this.limits();
      } catch (_) {
        limits = null;
      }
    }
    final decision = await _authorizer.authorize(
      token: token,
      kyc: kyc,
      featureEnabled: featureEnabled,
      kind: kind,
      amount: amount,
      currency: currency,
      biller: biller,
      mfaCode: mfaCode,
      challengeId: challengeId,
      knownLimits: limits,
    );
    if (!decision.allowed) throw TransactionBlocked(decision);
  }

  Future<WalletSnapshot> wallet() {
    return _api
        .get('/api/me/wallet', token: token)
        .then(WalletSnapshot.fromJson);
  }

  Future<ActivityBook> activity() {
    return _api
        .get('/api/me/activity', token: token)
        .then(ActivityBook.fromJson);
  }

  Future<TransferResult> transfer({
    required String phone,
    required double amount,
    required String currency,
    String? note,
    String? kyc,
    bool featureEnabled = true,
    String? mfaCode,
    String? challengeId,
  }) async {
    await _guard(
      kind: TransactionKind.send,
      amount: amount,
      currency: currency,
      kyc: kyc,
      featureEnabled: featureEnabled,
      mfaCode: mfaCode,
      challengeId: challengeId,
    );
    final json = await _api.post(
      '/api/me/transfers',
      token: token,
      body: {
        'phone': phone,
        'amount': amount,
        'currency': currency,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return TransferResult.fromJson(json);
  }

  Future<void> cash({
    required double amount,
    required String currency,
    required bool withdraw,
    String? kyc,
    bool featureEnabled = true,
    String? mfaCode,
    String? challengeId,
  }) async {
    await _guard(
      kind: withdraw ? TransactionKind.withdrawal : TransactionKind.deposit,
      amount: amount,
      currency: currency,
      kyc: kyc,
      featureEnabled: featureEnabled,
      mfaCode: mfaCode,
      challengeId: challengeId,
    );
    await _api.post(
      '/api/me/cash',
      token: token,
      body: {
        'amount': amount,
        'currency': currency,
        'action': withdraw ? 'withdraw' : 'deposit',
      },
    );
  }

  Future<AccountLimits?> limits() async {
    try {
      final json = await _api.get('/api/me/limits', token: token);
      return AccountLimits.fromJson(json);
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  Future<({bool biometrics, bool mfa})?> security() async {
    try {
      final json = await _api.get('/api/me/security', token: token);
      return (biometrics: json['biometrics'] == true, mfa: json['mfa'] == true);
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  Future<void> updateSecurity({required bool biometrics, required bool mfa}) {
    return _api.put(
      '/api/me/security',
      token: token,
      body: {'biometrics': biometrics, 'mfa': mfa},
    );
  }

  /// The tenant's autopay plan, or null when the method is not deployed yet.
  Future<AutopayPlan?> fetchAutopay() async {
    try {
      final json = await _api.get('/api/me/autopay', token: token);
      return AutopayPlan.fromJson(json);
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  /// Writes the plan. Returns null when the method is not deployed yet, so
  /// the phone keeps the copy it already saved locally.
  Future<AutopayPlan?> saveAutopay(AutopayPlan plan) async {
    try {
      final json = await _api.put(
        '/api/me/autopay',
        token: token,
        body: plan.toJson(),
      );
      if (json.isEmpty) return plan;
      return AutopayPlan.fromJson(json);
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  Future<ServicePayment> payService({
    required String serviceId,
    required double amount,
    required Map<String, String> fields,
    String currency = 'XAF',
    String? kyc,
    bool featureEnabled = true,
    String? mfaCode,
    String? challengeId,
  }) async {
    await _guard(
      kind: TransactionKind.bill,
      amount: amount,
      currency: currency,
      biller: serviceId,
      kyc: kyc,
      featureEnabled: featureEnabled,
      mfaCode: mfaCode,
      challengeId: challengeId,
    );
    final key =
        'svc-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
    final json = await _api.post(
      '/api/me/services/${Uri.encodeComponent(serviceId)}/pay',
      token: token,
      headers: {'Idempotency-Key': key},
      body: {
        'serviceId': serviceId,
        'amount': amount,
        'currency': currency,
        'fields': fields,
      },
    );
    return ServicePayment.fromJson(json);
  }

  Future<List<FeeInstitution>> institutions() async {
    final json = await _api.get('/api/fees/public/institutions');
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          FeeInstitution.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ];
  }

  Future<List<FeeOption>> fees(String code) async {
    final json = await _api.get('/api/fees/public/institutions/$code/fees');
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          FeeOption.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ];
  }

  Future<Map<String, dynamic>> payFee({
    required String institutionCode,
    required String periodId,
    required String categoryCode,
    required String studentReference,
    required String studentName,
    required double amount,
    String currency = 'XAF',
    String? kyc,
    bool featureEnabled = true,
    String? mfaCode,
    String? challengeId,
  }) async {
    await _guard(
      kind: TransactionKind.bill,
      amount: amount,
      currency: currency,
      biller: 'school_fees',
      kyc: kyc,
      featureEnabled: featureEnabled,
      mfaCode: mfaCode,
      challengeId: challengeId,
    );
    final key =
        'fee-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
    return _api.post(
      '/api/fees/payments',
      token: token,
      headers: {'Idempotency-Key': key},
      body: {
        'institutionCode': institutionCode,
        'academicPeriodId': periodId,
        'feeCategoryCode': categoryCode,
        'studentReference': studentReference,
        'studentName': studentName,
      },
    );
  }

  Future<Map<String, dynamic>> payBill({
    required String biller,
    required String reference,
    required double amount,
    String currency = 'XAF',
    String? kyc,
    bool featureEnabled = true,
    String? mfaCode,
    String? challengeId,
  }) async {
    await _guard(
      kind: TransactionKind.bill,
      amount: amount,
      currency: currency,
      biller: biller,
      kyc: kyc,
      featureEnabled: featureEnabled,
      mfaCode: mfaCode,
      challengeId: challengeId,
    );
    final key =
        'bill-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
    return _api.post(
      '/api/me/bills',
      token: token,
      headers: {'Idempotency-Key': key},
      body: {
        'biller': biller,
        'reference': reference,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  Future<List<AccountDevice>> devices() async {
    final json = await _api.get('/api/auth/devices', token: token);
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          AccountDevice.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ];
  }

  Future<int> signOutOthers() async {
    final json = await _api.post('/api/auth/sessions/others', token: token);
    return (json['revoked'] as num?)?.toInt() ?? 0;
  }
}
