/// Error envelope returned by the KumPay API (see backend spec §0.1).
///
/// The client switches on [code], never on [message]; messages are
/// user-facing copy and may change.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details = const {},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  /// Remaining verification attempts, when the server reports them.
  int? get remainingAttempts => details['remainingAttempts'] as int?;

  /// Seconds until the client may retry, when the server reports it.
  int? get retryAfterSec => details['retryAfterSec'] as int?;

  @override
  String toString() => 'ApiException($code): $message';
}

/// Codes the auth flow handles explicitly.
abstract final class AuthErrorCodes {
  static const invalidCode = 'INVALID_CODE';
  static const codeExpired = 'CODE_EXPIRED';
  static const tooManyAttempts = 'TOO_MANY_ATTEMPTS';
  static const rateLimited = 'RATE_LIMITED';
  static const deliveryFailed = 'DELIVERY_FAILED';
  static const validation = 'VALIDATION_ERROR';
  static const unauthenticated = 'UNAUTHENTICATED';
}
