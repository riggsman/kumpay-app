import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable id for this install, plus the fields the API stores on registration.
class DeviceIdentity {
  DeviceIdentity({FlutterSecureStorage? storage, this.appVersion = '0.1.0'})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kumpay.installation_id';

  final FlutterSecureStorage _storage;
  final String appVersion;

  Future<Map<String, String>> snapshot() async {
    var id = await _storage.read(key: _key);
    if (id == null || id.length < 8) {
      id = _newId();
      await _storage.write(key: _key, value: id);
    }
    return {
      'installationId': id,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'model': kIsWeb ? 'browser' : defaultTargetPlatform.name,
      'osVersion': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'appVersion': appVersion,
    };
  }

  String _newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
