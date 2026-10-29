import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'account_limits.dart';

enum TransactionKind {
  send('send'),
  deposit('deposit'),
  withdrawal('withdrawal'),
  bill('bill');

  const TransactionKind(this.wire);
  final String wire;
}

/// Codes the money-movement check understands.
abstract final class TransactionCodes {
  static const ok = 'OK';
  static const kycRequired = 'KYC_REQUIRED';
  static const limitReached = 'LIMIT_REACHED';
  static const featureDisabled = 'FEATURE_DISABLED';
  static const notAllowed = 'NOT_ALLOWED';
  static const accountRestricted = 'ACCOUNT_RESTRICTED';
  static const mfaRequired = 'MFA_REQUIRED';
  static const amountInvalid = 'AMOUNT_INVALID';
  static const network = 'NETWORK';
}

class TransactionDecision {
  const TransactionDecision({
    required this.allowed,
    required this.code,
    required this.message,
    this.limits,
    this.challengeId,
  });

  final bool allowed;
  final String code;
  final String message;
  final AccountLimits? limits;
  final String? challengeId;

  static const ok = TransactionDecision(
    allowed: true,
    code: TransactionCodes.ok,
    message: '',
  );

  factory TransactionDecision.fromJson(Map<String, dynamic> json) {
    final allowed = json['allowed'] == true;
    return TransactionDecision(
      allowed: allowed,
      code:
          json['code']?.toString() ??
          (allowed ? TransactionCodes.ok : TransactionCodes.notAllowed),
      message: json['message']?.toString() ?? '',
      limits: AccountLimits.tryParse(json['limits']),
      challengeId: json['challengeId']?.toString(),
    );
  }
}

class TransactionBlocked implements Exception {
  const TransactionBlocked(this.decision);

  final TransactionDecision decision;

  @override
  String toString() =>
      'TransactionBlocked(${decision.code}): ${decision.message}';
}

/// Asks the platform whether this account may move this amount right now.
abstract class TransactionCheckApi {
  Future<Map<String, dynamic>> authorize({
    required String token,
    required Map<String, dynamic> body,
  });
}

class HttpTransactionCheckApi implements TransactionCheckApi {
  HttpTransactionCheckApi({required String baseUrl, ApiClient? api})
    : _api = api ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _api;

  @override
  Future<Map<String, dynamic>> authorize({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _api.post(
      '/api/me/transactions/authorize',
      token: token,
      body: body,
    );
  }
}

class TransactionAuthorizer {
  TransactionAuthorizer({TransactionCheckApi? api, String baseUrl = ''})
    : _api = api ?? HttpTransactionCheckApi(baseUrl: baseUrl);

  final TransactionCheckApi _api;

  /// Local rules that do not need the network: flag, amount, verification, known caps.
  static TransactionDecision preview({
    required String? token,
    required String? kyc,
    required bool featureEnabled,
    required double amount,
    String currency = 'XAF',
    AccountLimits? knownLimits,
  }) {
    if (!featureEnabled) {
      return const TransactionDecision(
        allowed: false,
        code: TransactionCodes.featureDisabled,
        message: 'This service is turned off right now.',
      );
    }
    if (amount.isNaN || amount <= 0) {
      return const TransactionDecision(
        allowed: false,
        code: TransactionCodes.amountInvalid,
        message: 'Enter an amount greater than zero.',
      );
    }
    final signedIn = token != null && token.isNotEmpty;
    if (signedIn && kyc != null && kyc != 'approved') {
      return const TransactionDecision(
        allowed: false,
        code: TransactionCodes.kycRequired,
        message: 'Verify your identity before you can move money.',
      );
    }
    final reason = knownLimits?.blockReason(amount, currency);
    if (reason != null) {
      return TransactionDecision(
        allowed: false,
        code: TransactionCodes.limitReached,
        message: reason,
        limits: knownLimits,
      );
    }
    return TransactionDecision.ok;
  }

  /// Local rules first, then `POST /api/me/transactions/authorize`.
  ///
  /// A signed-out session is allowed through so design previews still work.
  /// HTTP 404 means the method is not deployed yet: local rules stand and the
  /// money endpoint remains the server check. Any other failure blocks the payment.
  Future<TransactionDecision> authorize({
    required String? token,
    required String? kyc,
    required bool featureEnabled,
    required TransactionKind kind,
    required double amount,
    required String currency,
    String? biller,
    String? mfaCode,
    String? challengeId,
    AccountLimits? knownLimits,
  }) async {
    final local = preview(
      token: token,
      kyc: kyc,
      featureEnabled: featureEnabled,
      amount: amount,
      currency: currency,
      knownLimits: knownLimits,
    );
    if (!local.allowed) return local;
    if (token == null || token.isEmpty) return local;
    try {
      final json = await _api.authorize(
        token: token,
        body: {
          'kind': kind.wire,
          'amount': amount,
          'currency': currency,
          if (biller != null && biller.isNotEmpty) 'biller': biller,
          if (mfaCode != null && mfaCode.isNotEmpty) 'mfaCode': mfaCode,
          if (challengeId != null && challengeId.isNotEmpty)
            'challengeId': challengeId,
        },
      );
      return TransactionDecision.fromJson(json);
    } on ApiException catch (error) {
      if (error.status == 404) return TransactionDecision.ok;
      if (_platformCodes.contains(error.code)) {
        return TransactionDecision(
          allowed: false,
          code: error.code,
          message: error.message,
          limits: AccountLimits.tryParse(error.details['limits']),
          challengeId: error.details['challengeId']?.toString(),
        );
      }
      return TransactionDecision(
        allowed: false,
        code: TransactionCodes.notAllowed,
        message: error.message,
      );
    } catch (_) {
      return const TransactionDecision(
        allowed: false,
        code: TransactionCodes.network,
        message: "Couldn't confirm this payment. Check your connection and try again.",
      );
    }
  }
}

const _platformCodes = {
  TransactionCodes.kycRequired,
  TransactionCodes.limitReached,
  TransactionCodes.featureDisabled,
  TransactionCodes.notAllowed,
  TransactionCodes.accountRestricted,
  TransactionCodes.mfaRequired,
  TransactionCodes.amountInvalid,
};
