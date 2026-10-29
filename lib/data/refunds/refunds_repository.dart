import '../../core/api_client.dart';

class RefundView {
  const RefundView({
    required this.id,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.status,
    this.reference,
    this.transactionId,
    this.resolution,
  });

  final String id;
  final double amount;
  final String currency;
  final String reason;
  final String status;
  final String? reference;
  final String? transactionId;
  final String? resolution;

  factory RefundView.fromJson(Map<String, dynamic> json) {
    final money = json['amount'];
    return RefundView(
      id: json['id']?.toString() ?? '',
      amount: money is Map ? (money['amount'] as num?)?.toDouble() ?? 0 : 0,
      currency: money is Map ? money['currency']?.toString() ?? '' : '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reference: json['reference']?.toString(),
      transactionId: json['transactionId']?.toString(),
      resolution: json['resolution']?.toString() == 'null' ? null : json['resolution']?.toString(),
    );
  }
}

class RefundsRepository {
  RefundsRepository({required String baseUrl, required this.token}) : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<List<RefundView>> list() async {
    final json = await _api.get('/api/me/refunds', token: token);
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          RefundView.fromJson(entry)
        else if (entry is Map)
          RefundView.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  Future<RefundView> create({
    required String transactionId,
    required double amount,
    required String currency,
    required String reason,
  }) {
    return _api
        .post(
          '/api/refunds',
          token: token,
          body: {
            'transactionId': transactionId,
            'amount': amount,
            'currency': currency,
            'reason': reason,
          },
        )
        .then(RefundView.fromJson);
  }
}
