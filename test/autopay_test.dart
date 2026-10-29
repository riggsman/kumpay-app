import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kumpay_uiux/core/api_client.dart';
import 'package:kumpay_uiux/data/money/money_repository.dart';
import 'package:kumpay_uiux/features/autopay/autopay_controller.dart';
import 'package:kumpay_uiux/features/autopay/autopay_plan.dart';
import 'package:kumpay_uiux/screens/bills/bills_screen.dart';
import 'package:kumpay_uiux/screens/profile/profile_screen.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';

void main() {
  setUp(autopayController.reset);

  test('a plan is off unless the tenant enables it', () {
    final plan = AutopayPlan.fromJson({
      'enabled': false,
      'rules': [
        {
          'id': 'ap_canal',
          'serviceId': 'canal',
          'serviceName': 'Canal+ Premium',
          'amount': 18000,
          'when': 'monthly',
          'dayOfMonth': 5,
        },
      ],
    });

    expect(plan.enabled, isFalse);
    expect(plan.active, isFalse);
    expect(plan.rules.single.detail, 'Every 5th · 18 000 FCFA');
  });

  test('a below-threshold rule keeps the amount and the trigger', () {
    final rule = AutopayRule.tryParse({
      'serviceId': 'eneo',
      'serviceName': 'ENEO prepaid',
      'amount': 10000,
      'when': 'below',
      'threshold': 5000,
    });

    expect(rule, isNotNull);
    expect(rule!.detail, 'When below 5 000 FCFA · pay 10 000 FCFA');
    expect(
        AutopayRule.tryParse({'serviceId': 'eneo', 'when': 'monthly'}), isNull);
  });

  test('the phone keeps a plan when KumPay cannot store it yet', () async {
    final next = AutopayPlan(
      enabled: true,
      rules: [
        AutopayRule(
          id: 'ap_eneo',
          serviceId: 'eneo',
          serviceName: 'ENEO prepaid',
          amount: 10000,
          when: AutopayWhen.below,
          threshold: 5000,
        ),
      ],
    );

    for (final client in [_StatusClient(404), _DownClient()]) {
      autopayController.reset();
      await autopayController.update(_repo(client), next);
      expect(autopayController.plan.enabled, isTrue);
      expect(autopayController.plan.rules.single.amount, 10000);
    }
  });

  test('a refused save puts the previous plan back', () async {
    await expectLater(
      autopayController.update(
        _repo(_StatusClient(400)),
        const AutopayPlan(enabled: true, rules: []),
      ),
      throwsA(isA<Exception>()),
    );
    expect(autopayController.plan.enabled, isFalse);
  });

  testWidgets('pay bills hides autopay until the tenant turns it on',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const BillsScreen()));
    await tester.pump();

    expect(find.text('Autopay'), findsNothing);
    expect(find.text('ENEO prepaid'), findsNothing);
    expect(find.text('Canal+ Premium'), findsNothing);
  });

  testWidgets('profile is where the tenant adds a service and an amount',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ProfileScreen()));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Autopay'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Off'), findsWidgets);
    await tester.tap(find.text('Autopay'));
    await tester.pumpAndSettle();

    expect(find.text('Enable autopay'), findsOneWidget);
    expect(find.text('Add a service'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a service'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '10000');
    await tester.tap(find.text('Save service'));
    await tester.pumpAndSettle();

    expect(find.text('ENEO prepaid'), findsOneWidget);
    expect(
        find.text('When below 5 000 FCFA · pay 10 000 FCFA'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const BillsScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('1 active'),
      80,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Autopay'), findsOneWidget);
    expect(find.text('ENEO prepaid'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);
  });
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) {
  return MaterialApp(
    theme: KpTheme.light(),
    builder: (context, child) => Material(child: child),
    home: home,
  );
}

MoneyRepository _repo(http.Client client) {
  return MoneyRepository(
    baseUrl: 'http://example.test',
    token: 'session',
    api: ApiClient(baseUrl: 'http://example.test', client: client),
  );
}

class _StatusClient extends http.BaseClient {
  _StatusClient(this.status);

  final int status;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(
        utf8.encode('{"error":{"code":"NO","message":"no"}}'),
      ),
      status,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _DownClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('offline');
  }
}
