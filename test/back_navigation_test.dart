import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/data/demo.dart';
import 'package:kumpay_uiux/screens/bills/bills_screen.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';
import 'package:kumpay_uiux/widgets/kp_controls.dart';
import 'package:kumpay_uiux/widgets/kp_shell.dart';

void main() {
  testWidgets('the first screen does not show a dead back arrow',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const _Welcome()));
    await tester.pump();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('a back arrow returns to the previous screen', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const _Start()));
    await tester.pump();

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.text('Meter details'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Meter details'), findsNothing);
  });

  testWidgets('back to home drops the screens pushed on top', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const _Start()));
    await tester.pump();

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Payment successful'), findsOneWidget);

    await tester.ensureVisible(find.text('Back to home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Meter details'), findsNothing);
    expect(find.text('Payment successful'), findsNothing);
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

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return const KpPage(
      header: KpAuthHeader(),
      children: [Text('Welcome')],
    );
  }
}

class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Start'),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _Details()),
              ),
              child: const Text('Open details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details();

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: const KpSimpleHeader(title: 'Details'),
      children: [
        const Text('Meter details'),
        KpButton(
          label: 'Open receipt',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BillSuccessScreen(
                bill: demoBills.first,
                amount: 10000,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
