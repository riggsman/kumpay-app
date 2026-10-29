import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'data/auth/auth_repository.dart';
import 'data/auth/device_identity.dart';
import 'data/auth/http_auth_repository.dart';
import 'data/auth/mock_auth_repository.dart';
import 'data/auth/session_store.dart';
import 'firebase/kum_pay_push.dart';
import 'state/auth_controller.dart';

/// OTP used only when the app is started with `--dart-define=KP_USE_MOCK=true`.
const String kMockOtp =
    String.fromEnvironment('KP_MOCK_OTP', defaultValue: '123456');

const bool kUseMock = bool.fromEnvironment('KP_USE_MOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final devices = DeviceIdentity();
  final AuthRepository repository = kUseMock
      ? MockAuthRepository(fixedCode: kMockOtp)
      : HttpAuthRepository(
          baseUrl: kApiBase,
          deviceIdentity: devices,
        );

  final controller = AuthController(
    repository: repository,
    sessionStore: SecureSessionStore(),
  );
  final push = KumPayPush(baseUrl: kApiBase, devices: devices);
  controller.addListener(() {
    unawaited(push.sync(controller.sessionToken));
  });
  await controller.restore();

  runApp(KumPayApp(authController: controller));
}
