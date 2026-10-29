import '../../core/api_client.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    this.body,
    this.resolution,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String subject;
  final String status;
  final String? body;
  final String? resolution;
  final String? createdAt;
  final String? resolvedAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      body: json['body']?.toString(),
      resolution: json['resolution']?.toString(),
      createdAt: json['createdAt']?.toString(),
      resolvedAt: json['resolvedAt']?.toString(),
    );
  }
}

class SupportRepository {
  SupportRepository({required String baseUrl, required this.token})
      : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<List<SupportTicket>> list() async {
    final json = await _api.get('/api/me/support/tickets', token: token);
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          SupportTicket.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))),
    ];
  }

  Future<SupportTicket> create({required String subject, required String body}) {
    return _api
        .post(
          '/api/support/tickets',
          token: token,
          body: {'subject': subject, 'body': body, 'channel': 'app'},
        )
        .then(SupportTicket.fromJson);
  }

  Future<SupportTicket> open(String id) {
    return _api.get('/api/me/support/tickets/$id', token: token).then(SupportTicket.fromJson);
  }
}
