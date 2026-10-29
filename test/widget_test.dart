import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpay_uiux/app.dart';
import 'package:kumpay_uiux/data/auth/mock_auth_repository.dart';
import 'package:kumpay_uiux/data/auth/session_store.dart';
import 'package:kumpay_uiux/features/auth/login_page.dart';
import 'package:kumpay_uiux/gallery/gallery.dart';
import 'package:kumpay_uiux/state/auth_controller.dart';
import 'package:kumpay_uiux/state/auth_scope.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';
import 'package:kumpay_uiux/widgets/kp_controls.dart';

void main() {
  AuthController controller() => AuthController(
        repository: MockAuthRepository(fixedCode: '123456'),
        sessionStore: MemorySessionStore(),
      );

  testWidgets('design gallery lists the artboards', (tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: KpTheme.light(), home: const KpGallery()));
    await tester.pump();

    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('login enables Send OTP only for a valid number', (tester) async {
    final auth = controller();
    await auth.restore();
    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: Material(
          child: AuthScope(controller: auth, child: const LoginPage()),
        ),
      ),
    );

    KpButton sendButton() => tester.widget<KpButton>(find.byType(KpButton));
    expect(sendButton().onTap, isNull);

    await tester.enterText(find.byType(TextField), '677 12');
    await tester.pump();
    expect(sendButton().onTap, isNull);

    await tester.enterText(find.byType(TextField), '677 12 34 56');
    await tester.pump();
    expect(sendButton().onTap, isNotNull);
  });

  testWidgets('signing in from login reaches the home screen', (tester) async {
    final auth = controller();
    await auth.restore();
    await tester.pumpWidget(KumPayApp(authController: auth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '677123456');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // The OTP page's hidden input is the only TextField on that route.
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isTrue);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('root shows login when signed out', (tester) async {
    final auth = controller();
    await auth.restore();
    await tester.pumpWidget(KumPayApp(authController: auth));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
