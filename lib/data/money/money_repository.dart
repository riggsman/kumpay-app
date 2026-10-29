import 'dart:math';

import '../../core/api_client.dart';
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

  String get label => currency == 'USD' ? '\$${amount.toStringAsFixed(2)}' : formatXaf(amount);
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
            phones.add((number: number, kind: entry['kind']?.toString() ?? 'primary'));
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
  const ActivityBook({required this.items, required this.moneyInXaf, required this.moneyOutXaf});

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
              ActivityItem.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
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
      name: json['displayName']?.toString() ?? json['legalName']?.toString() ?? '',
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
      label: '${json['feeCategoryName'] ?? json['feeCategory'] ?? 'Fee'} · ${json['academicPeriod'] ?? ''}'.trim(),
      amount: MoneyAmount.fromJson(json['amount']),
    );
  }
}

class AccountDevice {
  const AccountDevice({required this.model, required this.platform, required this.lastSeenAt});

  final String model;
  final String platform;
  final String? lastSeenAt;

  factory AccountDevice.fromJson(Map<String, dynamic> json) {
    final model = json['model']?.toString();
    return AccountDevice(
      model: model == null || model.isEmpty || model == 'null' ? (json['platform']?.toString() ?? 'Device') : model,
      platform: json['platform']?.toString() ?? '',
      lastSeenAt: json['lastSeenAt']?.toString(),
    );
  }
}

class MoneyRepository {
  MoneyRepository({required String baseUrl, required this.token}) : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<WalletSnapshot> wallet() {
    return _api.get('/api/me/wallet', token: token).then(WalletSnapshot.fromJson);
  }

  Future<ActivityBook> activity() {
    return _api.get('/api/me/activity', token: token).then(ActivityBook.fromJson);
  }

  Future<TransferResult> transfer({
    required String phone,
    required double amount,
    required String currency,
    String? note,
  }) {
    return _api
        .post(
          '/api/me/transfers',
          token: token,
          body: {
            'phone': phone,
            'amount': amount,
            'currency': currency,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        )
        .then(TransferResult.fromJson);
  }

  Future<void> cash({required double amount, required String currency, required bool withdraw}) {
    return _api.post(
      '/api/me/cash',
      token: token,
      body: {'amount': amount, 'currency': currency, 'action': withdraw ? 'withdraw' : 'deposit'},
    );
  }

  Future<List<FeeInstitution>> institutions() async {
    final json = await _api.get('/api/fees/public/institutions');
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map) FeeInstitution.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  Future<List<FeeOption>> fees(String code) async {
    final json = await _api.get('/api/fees/public/institutions/$code/fees');
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map) FeeOption.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  Future<Map<String, dynamic>> payFee({
    required String institutionCode,
    required String periodId,
    required String categoryCode,
    required String studentReference,
    required String studentName,
  }) {
    final key = 'fee-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
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

  Future<List<AccountDevice>> devices() async {
    final json = await _api.get('/api/auth/devices', token: token);
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map) AccountDevice.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  Future<int> signOutOthers() async {
    final json = await _api.post('/api/auth/sessions/others', token: token);
    return (json['revoked'] as num?)?.toInt() ?? 0;
  }
}
