import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kumpay_uiux/core/api_client.dart';
import 'package:kumpay_uiux/core/api_exception.dart';
import 'package:kumpay_uiux/data/money/money_repository.dart';
import 'package:kumpay_uiux/features/transactions/account_limits.dart';
import 'package:kumpay_uiux/features/transactions/transaction_authorizer.dart';

void main() {
  test(
    'an unverified account is stopped before the platform is asked',
    () async {
      final api = _RecordingApi();
      final authorizer = TransactionAuthorizer(api: api);

      final decision = await authorizer.authorize(
        token: 'session',
        kyc: 'unverified',
        featureEnabled: true,
        kind: TransactionKind.send,
        amount: 15000,
        currency: 'XAF',
      );

      expect(decision.allowed, isFalse);
      expect(decision.code, TransactionCodes.kycRequired);
      expect(api.calls, 0);
    },
  );

  test(
    'a switched-off service and a zero amount never reach the platform',
    () async {
      final api = _RecordingApi();
      final authorizer = TransactionAuthorizer(api: api);

      final disabled = await authorizer.authorize(
        token: 'session',
        kyc: 'approved',
        featureEnabled: false,
        kind: TransactionKind.withdrawal,
        amount: 1000,
        currency: 'XAF',
      );
      final empty = await authorizer.authorize(
        token: null,
        kyc: null,
        featureEnabled: true,
        kind: TransactionKind.deposit,
        amount: 0,
        currency: 'XAF',
      );

      expect(disabled.code, TransactionCodes.featureDisabled);
      expect(empty.code, TransactionCodes.amountInvalid);
      expect(api.calls, 0);
    },
  );

  test('known limits block the amount before the platform is asked', () async {
    final api = _RecordingApi();
    final authorizer = TransactionAuthorizer(api: api);
    const limits = AccountLimits(
      currency: 'XAF',
      remaining: 5000,
      perTransaction: 2000,
      dailyLimit: 10000,
    );

    final decision = await authorizer.authorize(
      token: 'session',
      kyc: 'approved',
      featureEnabled: true,
      kind: TransactionKind.send,
      amount: 2500,
      currency: 'XAF',
      knownLimits: limits,
    );

    expect(decision.allowed, isFalse);
    expect(decision.code, TransactionCodes.limitReached);
    expect(decision.message, contains('per-transaction'));
    expect(api.calls, 0);
  });

  test('the platform decision is honored, including a second factor', () async {
    final api = _RecordingApi(
      onCall: (body) async {
        if (body['mfaCode'] == null) {
          return {
            'allowed': false,
            'code': 'MFA_REQUIRED',
            'message': 'Enter the code from your authenticator.',
            'challengeId': 'ch-1',
          };
        }
        return {'allowed': true, 'code': 'OK', 'message': ''};
      },
    );
    final authorizer = TransactionAuthorizer(api: api);

    final first = await authorizer.authorize(
      token: 'session',
      kyc: 'approved',
      featureEnabled: true,
      kind: TransactionKind.bill,
      amount: 12500,
      currency: 'XAF',
      biller: 'eneo',
    );
    expect(first.code, TransactionCodes.mfaRequired);
    expect(first.challengeId, 'ch-1');

    final second = await authorizer.authorize(
      token: 'session',
      kyc: 'approved',
      featureEnabled: true,
      kind: TransactionKind.bill,
      amount: 12500,
      currency: 'XAF',
      biller: 'eneo',
      mfaCode: '482193',
      challengeId: first.challengeId,
    );
    expect(second.allowed, isTrue);
    expect(api.bodies.last['mfaCode'], '482193');
  });

  test('a missing authorize method leaves the local pass in place', () async {
    final api = _RecordingApi(
      onCall: (_) async => throw const ApiException(
        code: 'NOT_FOUND',
        message: 'missing',
        status: 404,
      ),
    );
    final decision = await TransactionAuthorizer(api: api).authorize(
      token: 'session',
      kyc: 'approved',
      featureEnabled: true,
      kind: TransactionKind.send,
      amount: 1000,
      currency: 'XAF',
    );
    expect(decision.allowed, isTrue);
  });

  test('the money call is not made when the platform refuses', () async {
    final httpClient = _BoomClient();
    final repository = MoneyRepository(
      baseUrl: 'http://example.test',
      token: 'session',
      api: ApiClient(baseUrl: 'http://example.test', client: httpClient),
      authorizer: TransactionAuthorizer(
        api: _RecordingApi(
          onCall: (_) async => {
            'allowed': false,
            'code': 'LIMIT_REACHED',
            'message': 'Daily limit reached.',
            'limits': {'currency': 'XAF', 'remaining': 0, 'dailyLimit': 50000},
          },
        ),
      ),
    );

    await expectLater(
      repository.transfer(
        phone: '+237677000000',
        amount: 10000,
        currency: 'XAF',
        kyc: 'approved',
      ),
      throwsA(
        isA<TransactionBlocked>().having(
          (error) => error.decision.code,
          'code',
          TransactionCodes.limitReached,
        ),
      ),
    );
    expect(httpClient.calls, 0);
  });

  test('an allowed check is followed by the transfer request', () async {
    final httpClient = _OkClient();
    final repository = MoneyRepository(
      baseUrl: 'http://example.test',
      token: 'session',
      api: ApiClient(baseUrl: 'http://example.test', client: httpClient),
      authorizer: TransactionAuthorizer(api: _RecordingApi()),
    );

    final result = await repository.transfer(
      phone: '+237677000000',
      amount: 1000,
      currency: 'XAF',
      kyc: 'approved',
    );

    expect(result.reference, 'KP-1');
    expect(httpClient.calls, 1);
  });
}

class _RecordingApi implements TransactionCheckApi {
  _RecordingApi({this.onCall});

  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)?
  onCall;
  final bodies = <Map<String, dynamic>>[];
  int calls = 0;

  @override
  Future<Map<String, dynamic>> authorize({
    required String token,
    required Map<String, dynamic> body,
  }) {
    calls++;
    bodies.add(body);
    final handler = onCall;
    if (handler != null) return handler(body);
    return Future.value({'allowed': true, 'code': 'OK', 'message': ''});
  }
}

class _BoomClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    calls++;
    throw StateError('money endpoint was called');
  }
}

class _OkClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    return http.StreamedResponse(
      Stream<List<int>>.value(
        utf8.encode(
          '{"reference":"KP-1","recipientName":"Aïcha","phone":"+237677000000","amount":{"amount":1000,"currency":"XAF"}}',
        ),
      ),
      200,
    );
  }
}
