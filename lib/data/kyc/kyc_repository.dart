import '../../core/api_client.dart';

class KycDocumentInfo {
  const KycDocumentInfo({required this.kind, required this.size});

  final String kind;
  final int size;

  factory KycDocumentInfo.fromJson(Map<String, dynamic> json) {
    return KycDocumentInfo(
      kind: json['kind']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class KycStatus {
  const KycStatus({required this.kyc, this.request});

  final String kyc;
  final KycRequestView? request;

  factory KycStatus.fromJson(Map<String, dynamic> json) {
    final raw = json['request'];
    return KycStatus(
      kyc: json['kyc']?.toString() ?? 'unverified',
      request: raw is Map<String, dynamic>
          ? KycRequestView.fromJson(raw)
          : raw is Map
              ? KycRequestView.fromJson(raw.map((key, value) => MapEntry(key.toString(), value)))
              : null,
    );
  }
}

class KycRequestView {
  const KycRequestView({
    required this.id,
    required this.status,
    required this.documents,
    this.reference,
    this.niu,
    this.rejectionReason,
  });

  final String id;
  final String status;
  final String? reference;
  final String? niu;
  final String? rejectionReason;
  final List<KycDocumentInfo> documents;

  factory KycRequestView.fromJson(Map<String, dynamic> json) {
    final raw = json['documents'];
    final documents = <KycDocumentInfo>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          documents.add(KycDocumentInfo.fromJson(entry));
        } else if (entry is Map) {
          documents.add(KycDocumentInfo.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))));
        }
      }
    }
    return KycRequestView(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reference: json['reference']?.toString(),
      niu: _text(json['niu']),
      rejectionReason: _text(json['rejectionReason']),
      documents: documents,
    );
  }

  bool has(String kind) => documents.any((document) => document.kind == kind);
}

class KycRepository {
  KycRepository({required String baseUrl, required this.token}) : _api = ApiClient(baseUrl: baseUrl);

  final String token;
  final ApiClient _api;

  Future<KycStatus> load() {
    return _api.get('/api/me/kyc', token: token).then(KycStatus.fromJson);
  }

  Future<KycRequestView> start() async {
    final json = await _api.post('/api/kyc/requests', token: token);
    return KycRequestView.fromJson(json);
  }

  Future<void> upload({
    required String requestId,
    required String kind,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) {
    return _api.postFile(
      '/api/kyc/requests/$requestId/documents?kind=$kind',
      token: token,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }
}

String? _text(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
