import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_client.dart';
import 'feature_flags_snapshot.dart';

/// The live stream is not deployed. Callers should keep polling.
class FeatureStreamUnsupported implements Exception {
  const FeatureStreamUnsupported();
}

/// Reads the platform feature snapshot.
abstract class FeatureFlagsRepository {
  Future<FeatureFlagsSnapshot> fetch();

  /// Pushes a full snapshot each time the platform changes a flag.
  Stream<FeatureFlagsSnapshot> watch();
}

class StaticFeatureFlagsRepository implements FeatureFlagsRepository {
  const StaticFeatureFlagsRepository(this.snapshot);

  final FeatureFlagsSnapshot snapshot;

  @override
  Future<FeatureFlagsSnapshot> fetch() async => snapshot;

  @override
  Stream<FeatureFlagsSnapshot> watch() =>
      Stream<FeatureFlagsSnapshot>.error(const FeatureStreamUnsupported());
}

class HttpFeatureFlagsRepository implements FeatureFlagsRepository {
  HttpFeatureFlagsRepository({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _api = ApiClient(baseUrl: baseUrl, client: client);

  final String baseUrl;
  final http.Client _client;
  final ApiClient _api;

  @override
  Future<FeatureFlagsSnapshot> fetch() async {
    final json = await _api.get('/api/features');
    return FeatureFlagsSnapshot.fromJson(json);
  }

  @override
  Stream<FeatureFlagsSnapshot> watch() async* {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final request = http.Request('GET', Uri.parse('$root/api/features/stream'));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 404) {
      throw const FeatureStreamUnsupported();
    }
    if (response.statusCode >= 400) {
      throw StateError('Feature stream failed (${response.statusCode}).');
    }
    final carry = StringBuffer();
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      carry.write(chunk);
      final scan = scanFeatureFlagSse(carry.toString());
      carry
        ..clear()
        ..write(scan.rest);
      for (final snapshot in scan.events) {
        yield snapshot;
      }
    }
  }
}

class FeatureFlagSseScan {
  const FeatureFlagSseScan(this.events, this.rest);

  final List<FeatureFlagsSnapshot> events;
  final String rest;
}

/// Splits a server-sent-event buffer into complete feature snapshots.
///
/// [rest] is the trailing incomplete event, kept for the next chunk.
FeatureFlagSseScan scanFeatureFlagSse(String buffered) {
  final normalized = buffered.replaceAll('\r\n', '\n');
  final blocks = normalized.split('\n\n');
  final complete = normalized.endsWith('\n\n')
      ? blocks.where((block) => block.isNotEmpty)
      : blocks.take(blocks.length - 1);
  final rest = normalized.endsWith('\n\n') ? '' : blocks.last;
  final events = <FeatureFlagsSnapshot>[];
  for (final block in complete) {
    final data = _eventData(block);
    if (data == null || data.isEmpty) continue;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        events.add(
          FeatureFlagsSnapshot.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    } catch (_) {
      // Ignore a malformed event and keep the stream open.
    }
  }
  return FeatureFlagSseScan(events, rest);
}

String? _eventData(String block) {
  final lines = <String>[];
  for (final raw in block.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty || line.startsWith(':')) continue;
    if (line.startsWith('data:')) {
      lines.add(line.substring(5).trimLeft());
    }
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}
