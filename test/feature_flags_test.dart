import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/features/feature_flags/app_feature.dart';
import 'package:kumpay_uiux/features/feature_flags/feature_flags_repository.dart';
import 'package:kumpay_uiux/features/feature_flags/feature_flags_snapshot.dart';
import 'package:kumpay_uiux/screens/bills/bills_screen.dart';
import 'package:kumpay_uiux/screens/home/home_screen.dart';
import 'package:kumpay_uiux/screens/wallet/top_up_screen.dart';
import 'package:kumpay_uiux/state/feature_flags_controller.dart';
import 'package:kumpay_uiux/state/feature_flags_scope.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';

void main() {
  test('snapshot keeps defaults for keys the platform omits', () {
    final snapshot = FeatureFlagsSnapshot.fromJson({
      'version': 4,
      'updatedAt': '2026-10-29T09:00:00Z',
      'flags': {'send': false, 'eneo': false},
    });

    expect(snapshot.version, 4);
    expect(snapshot.isEnabled(AppFeature.send), isFalse);
    expect(snapshot.isEnabled(AppFeature.eneo), isFalse);
    expect(snapshot.isEnabled(AppFeature.schoolFees), isTrue);
    expect(snapshot.isEnabled(AppFeature.camwater), isTrue);
    expect(AppFeature.forBillId('canal'), AppFeature.canalPlus);
  });

  test('an older version cannot turn a service back on', () {
    final controller = FeatureFlagsController(
      repository: const StaticFeatureFlagsRepository(
        FeatureFlagsSnapshot(flags: {}, version: 0),
      ),
    );
    addTearDown(controller.dispose);

    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 3,
        'flags': {'withdrawal': false, 'mfa': false},
      }),
    );
    expect(controller.isEnabled(AppFeature.withdrawal), isFalse);

    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 2,
        'flags': {'withdrawal': true},
      }),
    );
    expect(controller.isEnabled(AppFeature.withdrawal), isFalse);

    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 4,
        'flags': {'withdrawal': true},
      }),
    );
    expect(controller.isEnabled(AppFeature.withdrawal), isTrue);
  });

  test('server-sent events are applied as they arrive', () {
    const chunk = 'event: features\n'
        'data: {"version":2,"flags":{"send":false,"bills":false}}\n'
        '\n'
        ': ping\n'
        '\n'
        'data: {"version":3,"flags":{"camwater":false}}\n'
        '\n';
    final scan = scanFeatureFlagSse(chunk);
    expect(scan.rest, isEmpty);
    expect(scan.events, hasLength(2));
    expect(scan.events.first.isEnabled(AppFeature.send), isFalse);
    expect(scan.events.last.isEnabled(AppFeature.camwater), isFalse);
    expect(scan.events.last.isEnabled(AppFeature.send), isTrue);
  });

  test('a partial event stays buffered until it is complete', () {
    final first = scanFeatureFlagSse(
      'data: {"version":1,"flags":{"deposit":false}}',
    );
    expect(first.events, isEmpty);
    final second = scanFeatureFlagSse('${first.rest}\n\n');
    expect(second.events.single.isEnabled(AppFeature.deposit), isFalse);
  });

  testWidgets('home hides a service as soon as the platform turns it off', (
    tester,
  ) async {
    final repository = _ScriptedFlags([
      FeatureFlagsSnapshot.defaults(),
      FeatureFlagsSnapshot.fromJson({
        'version': 2,
        'flags': {'send': false, 'bills': false, 'deposit': false},
      }),
    ]);
    final controller = FeatureFlagsController(
      repository: repository,
      pollInterval: const Duration(milliseconds: 40),
    );

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: KpTheme.light(),
          home: FeatureFlagsScope(
            controller: controller,
            child: const Material(child: HomeScreen()),
          ),
        ),
      );
      expect(find.text('Send'), findsWidgets);
      expect(find.text('Pay bills'), findsOneWidget);
      expect(find.text('Add money'), findsWidgets);

      await controller.start();
      await tester.pump();
      expect(find.text('Send'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('Send'), findsNothing);
      expect(find.text('Pay bills'), findsNothing);
      expect(find.text('Add money'), findsNothing);
      expect(find.text('Card'), findsOneWidget);
    } finally {
      controller.dispose();
    }
  });

  testWidgets('a disabled biller disappears from pay bills', (tester) async {
    final snapshot = FeatureFlagsSnapshot.fromJson({
      'version': 1,
      'flags': {'eneo': false, 'canal_plus': false},
    });
    final controller = FeatureFlagsController(
      repository: StaticFeatureFlagsRepository(snapshot),
    );
    controller.applySnapshot(snapshot);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: FeatureFlagsScope(
          controller: controller,
          child: const Material(child: BillsScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ENEO Electricity'), findsNothing);
    expect(find.text('Canal+'), findsNothing);
    expect(find.text('CAMWATER'), findsOneWidget);
    expect(find.text('DStv'), findsOneWidget);
  });

  test('an alert is on only when the platform enables it and gives it a title',
      () {
    final on = FeatureFlagsSnapshot.fromJson({
      'version': 5,
      'alert': {
        'enabled': true,
        'title': 'Market day',
        'body': 'Fees are waived until Sunday.',
        'action': 'wallet',
      },
    });
    final off = FeatureFlagsSnapshot.fromJson({
      'version': 6,
      'alert': {'enabled': false, 'title': 'Market day'},
    });

    expect(on.alert?.enabled, isTrue);
    expect(on.alert?.title, 'Market day');
    expect(on.alert?.message, 'Fees are waived until Sunday.');
    expect(on.alert?.action, 'wallet');
    expect(off.alert?.enabled, isFalse);
    expect(FeatureFlagsSnapshot.fromJson({'version': 1}).alert, isNull);
  });

  testWidgets('home follows the platform marketing alert', (tester) async {
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
        'alert': {
          'enabled': true,
          'title': 'Market day',
          'message': 'Fees are waived until Sunday.',
          'action': 'bills',
        },
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

    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.text('Market day'), findsOneWidget);
    expect(find.text('Fees are waived until Sunday.'), findsOneWidget);
    expect(find.text('Zero fees on ENEO this week'), findsNothing);

    controller.applySnapshot(
      FeatureFlagsSnapshot.fromJson({
        'version': 3,
        'flags': {'bills': true},
        'alert': {'enabled': false},
      }),
    );
    await tester.pump();

    expect(find.text('Market day'), findsNothing);
    expect(find.text('Zero fees on ENEO this week'), findsNothing);
  });

  testWidgets('add money opens the deposit screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        builder: (context, child) => Material(child: child),
        home: const HomeScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Add money').first);
    await tester.pumpAndSettle();

    expect(find.byType(TopUpScreen), findsOneWidget);
    expect(find.text('How much do you want to add?'), findsOneWidget);
    expect(find.text('Linked accounts'), findsNothing);
  });
}

class _ScriptedFlags implements FeatureFlagsRepository {
  _ScriptedFlags(this.pages);

  final List<FeatureFlagsSnapshot> pages;
  var _index = 0;

  @override
  Future<FeatureFlagsSnapshot> fetch() async {
    final page = pages[_index.clamp(0, pages.length - 1)];
    if (_index < pages.length - 1) _index++;
    return page;
  }

  @override
  Stream<FeatureFlagsSnapshot> watch() =>
      Stream<FeatureFlagsSnapshot>.error(const FeatureStreamUnsupported());
}
