import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'gallery/gallery.dart';
import 'preview/preview_page.dart';
import 'screens/home/home_screen.dart';
import 'state/auth_controller.dart';
import 'state/auth_scope.dart';
import 'theme/kp_theme.dart';
import 'widgets/kp_brand.dart';

class KumPayApp extends StatelessWidget {
  const KumPayApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    // AuthScope sits above MaterialApp so every route, including screens
    // pushed by the Navigator, can reach the session.
    return AuthScope(
      controller: authController,
      child: MaterialApp(
        title: 'KumPay',
        debugShowCheckedModeBanner: false,
        theme: KpTheme.light(),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        // One Material around the whole Navigator, so every pushed route has
        // the ink and background ancestors the screens rely on.
        builder: (context, child) => Material(
          color: KpColors.canvas,
          child: child,
        ),
        // The design gallery exists only in design review builds.
        home: kDesignPreview ? const KpGallery() : const _RootGate(),
      ),
    );
  }
}

/// Chooses the first screen from the session state.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final status = AuthScope.of(context).status;
    return switch (status) {
      AuthStatus.unknown => const _Splash(),
      AuthStatus.signedIn => const HomeScreen(),
      AuthStatus.signedOut => const LoginPage(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KpBrand(),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
