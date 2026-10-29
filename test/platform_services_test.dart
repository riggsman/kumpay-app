import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/features/feature_flags/feature_flags_repository.dart';
import 'package:kumpay_uiux/features/feature_flags/feature_flags_snapshot.dart';
import 'package:kumpay_uiux/features/services/platform_service.dart';
import 'package:kumpay_uiux/features/services/service_pay_page.dart';
import 'package:kumpay_uiux/features/transactions/account_limits.dart';
import 'package:kumpay_uiux/features/transactions/transaction_gate.dart';
import 'package:kumpay_uiux/screens/home/home_screen.dart';
import 'package:kumpay_uiux/state/feature_flags_controller.dart';
import 'package:kumpay_uiux/state/feature_flags_scope.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';

void main() {
  const council = {
    'serviceName': 'council',
    'logo': 'council.png',
    'fields': ['amount', 'type'],
  };

  test('council renders the name, logo, and only the fields that were sent',
      () {
    final service = PlatformService.tryParse(council);

    expect(service, isNotNull);
    expect(service!.id, 'council');
    expect(service.name, 'council');
    expect(service.fields.map((field) => field.label), ['Amount', 'Type']);
    expect(
      service.fields.map((field) => field.key),
      [ServiceFieldKey.amount, ServiceFieldKey.type],
    );
    expect(
      service.logoUrl('http://127.0.0.1:8000/'),
      'http://127.0.0.1:8000/media/services/council.png',
    );
    expect(service.resolveAmount('5 000 FCFA'), 5000);
  });

  test('a service with no recognized field is not shown', () {
    expect(
      PlatformService.tryParse({
        'serviceName': 'council',
        'fields': ['phone', 'note'],
      }),
      isNull,
    );
    expect(
      PlatformService.tryParse({
        'serviceName': 'council',
        'fields': [],
      }),
      isNull,
    );
    expect(
      PlatformService.tryParse({
        'serviceName': 'council',
        'enabled': false,
        'fields': ['amount'],
      }),
      isNull,
    );
  });

  test('labels come from the platform and extra fields are dropped', () {
    final service = PlatformService.tryParse({
      'id': 'levy',
      'name': 'City levy',
      'fields': [
        {'key': 'amount', 'label': 'Levy'},
        'amount',
        {'name': 'receiver', 'label': 'Taxpayer'},
        {
          'key': 'type',
          'label': 'Levy type',
          'options': ['Market', 'Property']
        },
        {'key': 'note', 'label': 'Note'},
      ],
    });

    expect(service!.fields.map((field) => field.label), [
      'Levy',
      'Taxpayer',
      'Levy type',
    ]);
    expect(service.fields.last.options, ['Market', 'Property']);
  });

  test('a fixed amount is used when the platform did not ask for one', () {
    final service = PlatformService.tryParse({
      'serviceName': 'council',
      'fixedAmount': 2500,
      'fields': ['receiver'],
    })!;

    expect(service.asksForAmount, isFalse);
    expect(service.resolveAmount(null), 2500);
  });

  test('provider settlement is reported by the pay response', () {
    final covered = ServicePayment.fromJson({
      'status': 'debited',
      'reference': 'KP-SVC-1',
    });
    final short = ServicePayment.fromJson({'status': 'provider_pending'});

    expect(covered.providerRequested, isFalse);
    expect(covered.message, contains('KumPay balance'));
    expect(short.providerRequested, isTrue);
    expect(short.message, contains('provider request'));
  });

  test('quarterly and annual remaining stop the payment', () {
    const limits = AccountLimits(
      currency: 'XAF',
      perTransaction: 500000,
      monthly: PeriodLimit(period: 'monthly', limit: 80000, remaining: 80000),
      quarterly: PeriodLimit(period: 'quarterly', remaining: 1000),
      annual: PeriodLimit(period: 'annual', remaining: 900000),
    );

    expect(limits.blockReason(5000, 'XAF'), contains('quarterly'));
    expect(
      const AccountLimits(
        currency: 'XAF',
        annual: PeriodLimit(period: 'annual', remaining: 4000),
      ).blockReason(9000, 'XAF'),
      contains('annual'),
    );
    expect(limits.summary, contains('Quarterly'));
    expect(limits.compact, '80 000 FCFA');
  });

  test('a new service on a later snapshot is published to the app', () {
    final controller = FeatureFlagsController(
      repository: const StaticFeatureFlagsRepository(
        FeatureFlagsSnapshot(flags: {}, version: 0),
      ),
    );
    addTearDown(controller.dispose);
    var notices = 0;
    controller.addListener(() => notices++);

    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 2,
        'flags': {'bills': true},
        'services': [council],
      }),
    );

    expect(notices, 1);
    expect(controller.snapshot.services.single.name, 'council');
    expect(controller.snapshot.services.single.fields, hasLength(2));
  });

  test('the features stream carries services in the same event as flags', () {
    const chunk = 'data: {"version":4,"flags":{"bills":true},"services":'
        '[{"serviceName":"council","logo":"council.png","fields":["amount","type"]}]}\n'
        '\n';
    final scan = scanFeatureFlagSse(chunk);

    expect(scan.rest, isEmpty);
    expect(scan.events.single.services.single.name, 'council');
  });

  testWidgets('home shows a new service and drops it when the platform does', (
    tester,
  ) async {
    final controller = FeatureFlagsController(
      repository: const StaticFeatureFlagsRepository(
        FeatureFlagsSnapshot(flags: {}, version: 0),
      ),
    );
    addTearDown(controller.dispose);
    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 2,
        'flags': {'bills': true},
        'services': [council],
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: FeatureFlagsScope(
          controller: controller,
          child: const Material(child: HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New services'), findsOneWidget);
    expect(find.text('council'), findsOneWidget);

    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 3,
        'flags': {'bills': false},
        'services': [council],
      }),
    );
    await tester.pump();

    expect(find.text('council'), findsNothing);
    expect(find.text('New services'), findsNothing);
  });

  testWidgets('the pay screen renders the platform labels and nothing else', (
    tester,
  ) async {
    final service = PlatformService.tryParse({
      'serviceName': 'council',
      'fields': [
        {'key': 'amount', 'label': 'Levy'},
        {
          'key': 'type',
          'label': 'Levy type',
          'options': ['Market', 'Property']
        },
      ],
    })!;
    final controller = FeatureFlagsController(
      repository: const StaticFeatureFlagsRepository(
        FeatureFlagsSnapshot(flags: {}, version: 0),
      ),
    );
    addTearDown(controller.dispose);
    controller.applySnapshot(
      FeatureFlagsSnapshot(
        flags: const {'bills': true},
        version: 2,
        services: [service],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: FeatureFlagsScope(
          controller: controller,
          child: Material(child: ServicePayPage(service: service)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('council'), findsWidgets);
    expect(find.text('Levy'), findsOneWidget);
    expect(find.text('Levy type'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Receiver'), findsNothing);
    expect(find.text('Amount'), findsNothing);
  });

  testWidgets('a platform service stays payable when school fees are off', (
    tester,
  ) async {
    final controller = FeatureFlagsController(
      repository: const StaticFeatureFlagsRepository(
        FeatureFlagsSnapshot(flags: {}, version: 0),
      ),
    );
    addTearDown(controller.dispose);
    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 2,
        'flags': {'bills': true, 'school_fees': false},
      }),
    );
    late bool councilOn;
    late bool feesOn;

    await tester.pumpWidget(
      MaterialApp(
        home: FeatureFlagsScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              councilOn = billFeatureEnabled(context, 'council');
              feesOn = billFeatureEnabled(context, 'school_fees');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(councilOn, isTrue);
    expect(feesOn, isFalse);
  });
}
