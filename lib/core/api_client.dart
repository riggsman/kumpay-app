import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// JSON client for the KumPay API error envelope.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return _send(() => _client.get(_uri(path), headers: _headers(token)));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    String? token,
    Object? body,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.post(
        _uri(path),
        headers: {
          ..._headers(token, json: body != null),
          ...?headers,
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    String? token,
    Object? body,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.put(
        _uri(path),
        headers: {
          ..._headers(token, json: body != null),
          ...?headers,
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> postFile(
    String path, {
    required String token,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers(token));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    return _send(() async {
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    });
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) {
    return _send(() => _client.delete(_uri(path), headers: _headers(token)));
  }

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path');
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() call,
  ) async {
    final http.Response response;
    try {
      response = await call().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ApiException(
        code: 'NETWORK',
        message: "Couldn't reach KumPay. Check your connection and try again.",
      );
    }
    final json = _decode(response);
    if (response.statusCode >= 400) throw _error(json, response.statusCode);
    return json;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return {};
  }

  ApiException _error(Map<String, dynamic> body, int status) {
    final error = body['error'];
    if (error is Map) {
      final details = <String, Object?>{};
      final raw = error['details'];
      if (raw is Map) {
        raw.forEach((key, value) => details[key.toString()] = value);
      }
      return ApiException(
        code: error['code']?.toString() ?? AuthErrorCodes.validation,
        message: error['message']?.toString() ?? 'Request failed.',
        details: details,
        status: status,
      );
    }
    return ApiException(
      code: AuthErrorCodes.validation,
      message: 'Request failed ($status).',
      status: status,
    );
  }

  Map<String, String> _headers(String? token, {bool json = false}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
