import '../../core/api_exception.dart';

/// User-facing copy for auth failures. Keyed on the stable error code, never
/// on the server's message text.
String authErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case AuthErrorCodes.validation:
        return 'Enter a valid Cameroon phone number.';
      case AuthErrorCodes.rateLimited:
        final wait = error.retryAfterSec;
        return wait == null
            ? 'Please wait before requesting another code.'
            : 'Please wait ${_humanWait(wait)} before requesting another code.';
      case AuthErrorCodes.deliveryFailed:
        return "We couldn't deliver your code. Contact support at support@kumpay.cm.";
      case AuthErrorCodes.invalidCode:
        final left = error.remainingAttempts;
        return left == null
            ? 'Incorrect code. Check the 6 digits and try again.'
            : 'Incorrect code. $left ${left == 1 ? 'attempt' : 'attempts'} left.';
      case AuthErrorCodes.codeExpired:
        return 'This code has expired. Request a new one.';
      case AuthErrorCodes.tooManyAttempts:
        final wait = error.retryAfterSec;
        return wait == null
            ? 'Too many attempts. Try again later.'
            : 'Too many attempts. Try again in ${_humanWait(wait)}.';
      case AuthErrorCodes.unauthenticated:
        return 'Your session has ended. Please sign in again.';
    }
    return error.message;
  }
  return "Couldn't reach KumPay. Check your connection and try again.";
}

String _humanWait(int seconds) {
  if (seconds < 60) return '$seconds seconds';
  final minutes = (seconds / 60).ceil();
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}
