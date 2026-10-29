/// Backend origin. Override for a device that cannot reach localhost:
/// `--dart-define=KP_API_BASE=http://10.0.2.2:8000`
const String kApiBase = String.fromEnvironment(
  'KP_API_BASE',
  defaultValue: 'http://127.0.0.1:8000',
);
