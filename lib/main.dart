import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'data/auth/auth_repository.dart';
import 'data/auth/device_identity.dart';
import 'data/auth/http_auth_repository.dart';
import 'data/auth/mock_auth_repository.dart';
import 'data/auth/session_store.dart';
import 'features/feature_flags/feature_flags_repository.dart';
import 'features/feature_flags/feature_flags_snapshot.dart';
import 'firebase/kum_pay_push.dart';
import 'preview/preview_page.dart';
import 'state/auth_controller.dart';
import 'state/feature_flags_controller.dart';

/// OTP used only when the app is started with `--dart-define=KP_USE_MOCK=true`.
const String kMockOtp = String.fromEnvironment(
  'KP_MOCK_OTP',
  defaultValue: '123456',
);

const bool kUseMock = bool.fromEnvironment('KP_USE_MOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final devices = DeviceIdentity();
  final AuthRepository repository = kUseMock
      ? MockAuthRepository(fixedCode: kMockOtp)
      : HttpAuthRepository(baseUrl: kApiBase, deviceIdentity: devices);

  final controller = AuthController(
    repository: repository,
    sessionStore: SecureSessionStore(),
  );
  final push = KumPayPush(baseUrl: kApiBase, devices: devices);
  controller.addListener(() {
    unawaited(push.sync(controller.sessionToken));
  });
  await controller.restore();

  final flags = FeatureFlagsController(
    repository: kDesignPreview
        ? StaticFeatureFlagsRepository(FeatureFlagsSnapshot.defaults())
        : HttpFeatureFlagsRepository(baseUrl: kApiBase),
  );
  if (!kDesignPreview) unawaited(flags.start());

  runApp(KumPayApp(authController: controller, featureFlags: flags));
}
