import '../../core/api_client.dart';

class ClientNotice {
  const ClientNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.read,
    this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final bool read;
  final String? createdAt;

  factory ClientNotice.fromJson(Map<String, dynamic> json) {
    return ClientNotice(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class ClientInbox {
  const ClientInbox({required this.items, required this.unreadCount});

  final List<ClientNotice> items;
  final int unreadCount;

  factory ClientInbox.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <ClientNotice>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          items.add(ClientNotice.fromJson(entry));
        } else if (entry is Map) {
          items.add(ClientNotice.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))));
        }
      }
    }
    return ClientInbox(
      items: items,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? items.where((item) => !item.read).length,
    );
  }
}

class NotificationsRepository {
  NotificationsRepository({required String baseUrl, required this.token})
      : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<ClientInbox> list({String? kind}) {
    final query = kind == null || kind.isEmpty ? '' : '?kind=$kind';
    return _api.get('/api/me/notifications$query', token: token).then(ClientInbox.fromJson);
  }

  Future<int> unreadCount() async {
    final json = await _api.get('/api/me/notifications/unread-count', token: token);
    return (json['count'] as num?)?.toInt() ?? 0;
  }

  Future<ClientNotice> open(String id) {
    return _api.get('/api/me/notifications/$id', token: token).then(ClientNotice.fromJson);
  }

  Future<int> markAllRead() async {
    final json = await _api.post('/api/me/notifications/read-all', token: token);
    return (json['marked'] as num?)?.toInt() ?? 0;
  }
}
