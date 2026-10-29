import '../../core/api_client.dart';

class VirtualCard {
  const VirtualCard({
    required this.id,
    required this.label,
    required this.type,
    required this.last4,
    required this.expiry,
    required this.status,
    required this.amount,
    required this.currency,
  });

  final String id;
  final String label;
  final String type;
  final String last4;
  final String expiry;
  final String status;
  final double amount;
  final String currency;

  factory VirtualCard.fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];
    return VirtualCard(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      last4: json['last4']?.toString() ?? '',
      expiry: json['expiry']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      amount: balance is Map ? (balance['amount'] as num?)?.toDouble() ?? 0 : 0,
      currency: balance is Map ? balance['currency']?.toString() ?? '' : '',
    );
  }
}

class CardCreation {
  const CardCreation({required this.card, required this.free});

  final VirtualCard card;
  final bool free;
}

class CardsRepository {
  CardsRepository({required String baseUrl, required this.token}) : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<List<VirtualCard>> list() async {
    final json = await _api.get('/api/cards', token: token);
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          VirtualCard.fromJson(entry)
        else if (entry is Map)
          VirtualCard.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  Future<CardCreation> create(String type) async {
    final json = await _api.post('/api/cards', token: token, body: {'type': type});
    final creation = json['creation'];
    return CardCreation(
      card: VirtualCard.fromJson(json),
      free: creation is Map && creation['free'] == true,
    );
  }
}
