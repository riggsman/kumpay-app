import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../data/auth/device_identity.dart';

/// Client Firebase settings pasted into `web/firebase-config.json`.
class FirebaseConfig {
  const FirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.authDomain,
    required this.storageBucket,
    required this.vapidKey,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String authDomain;
  final String storageBucket;
  final String vapidKey;

  bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty &&
      !apiKey.startsWith('PASTE') &&
      !projectId.startsWith('PASTE');

  FirebaseOptions toOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
    );
  }

  static Future<FirebaseConfig> load() async {
    try {
      final raw = await rootBundle.loadString('web/firebase-config.json');
      final json = jsonDecode(raw);
      if (json is! Map) return _empty;
      String value(String key) => (json[key] ?? '').toString().trim();
      return FirebaseConfig(
        apiKey: value('apiKey'),
        appId: value('appId'),
        messagingSenderId: value('messagingSenderId'),
        projectId: value('projectId'),
        authDomain: value('authDomain'),
        storageBucket: value('storageBucket'),
        vapidKey: value('vapidKey'),
      );
    } catch (_) {
      return _empty;
    }
  }

  static const _empty = FirebaseConfig(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    authDomain: '',
    storageBucket: '',
    vapidKey: '',
  );
}

/// Asks Firebase for this install's token and stores it on the captured device.
class KumPayPush {
  KumPayPush({
    required this.baseUrl,
    required DeviceIdentity devices,
    http.Client? client,
  })  : _devices = devices,
        _client = client ?? http.Client();

  final String baseUrl;
  final DeviceIdentity _devices;
  final http.Client _client;
  bool _ready = false;
  bool _busy = false;

  Future<void> sync(String? sessionToken) async {
    if (sessionToken == null || sessionToken.isEmpty || _busy) return;
    if (!_supported) return;
    _busy = true;
    try {
      final config = await FirebaseConfig.load();
      if (!config.isConfigured) return;
      if (!_ready) {
        await Firebase.initializeApp(options: config.toOptions());
        FirebaseMessaging.onBackgroundMessage(_backgroundMessage);
        _ready = true;
      }
      await FirebaseMessaging.instance.requestPermission();
      final vapid = config.vapidKey.isEmpty ? null : config.vapidKey;
      final pushToken = await FirebaseMessaging.instance.getToken(vapidKey: vapid);
      if (pushToken == null || pushToken.isEmpty) return;
      final installationId = (await _devices.snapshot())['installationId'];
      if (installationId == null || installationId.length < 8) return;
      final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      await _client.post(
        Uri.parse('$root/api/auth/devices/push'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
        body: jsonEncode({
          'installationId': installationId,
          'pushToken': pushToken,
        }),
      );
    } catch (_) {
      // An empty or incomplete paste must not block sign-in.
    } finally {
      _busy = false;
    }
  }

  bool get _supported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundMessage(RemoteMessage message) async {}
