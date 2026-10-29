import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/screens/cards/card_screen.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';

/// Matches screens_render_test: Ahem makes every glyph a full em and the
/// card metrics row overflows a 390-wide phone. DejaVu is the suite font.
const _testFontFamily = 'KpTestSans';

Future<void> _loadRealisticFonts() async {
  final regular = _fontFile([
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
  ]);
  final bold = _fontFile([
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    '/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf',
  ]);
  if (regular == null || bold == null) return;
  final loader = FontLoader(_testFontFamily)
    ..addFont(Future.value(ByteData.view(regular.readAsBytesSync().buffer)))
    ..addFont(Future.value(ByteData.view(bold.readAsBytesSync().buffer)));
  await loader.load();
}

File? _fontFile(List<String> paths) {
  for (final path in paths) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}

ThemeData _testTheme() {
  final base = KpTheme.light();
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: _testFontFamily),
  );
}

void main() {
  setUpAll(_loadRealisticFonts);

  testWidgets('freeze and unfreeze ask before they change the card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: _testTheme(),
        builder: (context, child) => Material(child: child),
        home: const CardScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Frozen'), findsNothing);

    await tester.tap(find.text('Freeze'));
    await tester.pumpAndSettle();
    expect(find.text('Freeze this card?'), findsOneWidget);
    expect(find.text('Freeze card'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Freeze this card?'), findsNothing);
    expect(find.text('Freeze'), findsOneWidget);
    expect(find.text('Frozen'), findsNothing);

    await tester.tap(find.text('Freeze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Freeze card'));
    await tester.pumpAndSettle();

    expect(find.text('Freeze this card?'), findsNothing);
    expect(find.text('Frozen'), findsOneWidget);
    expect(find.text('Unfreeze'), findsOneWidget);

    await tester.tap(find.text('Unfreeze'));
    await tester.pumpAndSettle();
    expect(find.text('Unfreeze this card?'), findsOneWidget);
    await tester.tap(find.text('Unfreeze card'));
    await tester.pumpAndSettle();

    expect(find.text('Unfreeze this card?'), findsNothing);
    expect(find.text('Frozen'), findsNothing);
    expect(find.text('Freeze'), findsOneWidget);
  });
}
