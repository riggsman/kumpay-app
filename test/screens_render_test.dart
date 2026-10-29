import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kumpay_uiux/data/demo.dart';
import 'package:kumpay_uiux/screens/auth/account_entry_screen.dart';
import 'package:kumpay_uiux/screens/auth/change_phone_screen.dart';
import 'package:kumpay_uiux/screens/auth/device_screens.dart';
import 'package:kumpay_uiux/screens/auth/help_screens.dart';
import 'package:kumpay_uiux/screens/auth/otp_sent_screen.dart';
import 'package:kumpay_uiux/screens/auth/otp_verify_screen.dart';
import 'package:kumpay_uiux/screens/auth/registration_screen.dart';
import 'package:kumpay_uiux/screens/auth/secure_account_screen.dart';
import 'package:kumpay_uiux/screens/auth/state_screens.dart';
import 'package:kumpay_uiux/screens/bills/bills_screen.dart';
import 'package:kumpay_uiux/screens/cards/card_screen.dart';
import 'package:kumpay_uiux/screens/home/home_screen.dart';
import 'package:kumpay_uiux/screens/kyc/kyc_screens.dart';
import 'package:kumpay_uiux/screens/profile/autopay_page.dart';
import 'package:kumpay_uiux/screens/profile/change_pin_screen.dart';
import 'package:kumpay_uiux/screens/profile/language_screen.dart';
import 'package:kumpay_uiux/screens/profile/profile_screen.dart';
import 'package:kumpay_uiux/screens/wallet/activity_screen.dart';
import 'package:kumpay_uiux/screens/wallet/top_up_screen.dart';
import 'package:kumpay_uiux/screens/wallet/transfer_screen.dart';
import 'package:kumpay_uiux/screens/wallet/wallet_screen.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';

/// Every artboard is pumped inside a 390x844 phone-sized surface. Any layout
/// overflow or build exception fails the test for that screen.
final _screens = <String, Widget Function()>{
  'Login': () => const AccountEntryScreen(),
  'Change number': () => const ChangePhoneScreen(),
  'OTP sent': () => const OtpSentScreen(),
  'Verify OTP': () => const OtpVerifyScreen(),
  'OTP keyboard': () => const OtpVerifyScreen(mode: OtpMode.keyboard),
  'Incorrect OTP': () => const OtpVerifyScreen(mode: OtpMode.incorrect),
  'Code expired': () => const OtpExpiredScreen(),
  'Too many attempts': () => const OtpLockedScreen(),
  'OTP resent': () => const OtpSentScreen(resent: true),
  'Confirm device': () => const DeviceConfirmScreen(),
  'Device details': () => const DeviceDetailsScreen(),
  'Device changed': () => const DeviceSuccessScreen(),
  'Signed out elsewhere': () => const LoggedOutNoticeScreen(),
  'Help & support': () => const HelpScreen(),
  'Security tips': () => const SecurityTipsScreen(),
  'Device failed': () => const DeviceFailedScreen(),
  'Sending OTP': () => const SendingOtpScreen(),
  'Verifying OTP': () => const VerifyingOtpScreen(),
  'Resend ready': () => const OtpVerifyScreen(mode: OtpMode.resendReady),
  'Secure account': () => const SecureAccountScreen(),
  'Invalid account': () => const InvalidAccountScreen(),
  'Network error': () => const NetworkErrorScreen(),
  'Create account': () => const RegistrationScreen(),
  'KYC intro': () => const KycIntroScreen(),
  'KYC form': () => const KycFormScreen(),
  'KYC submitted': () => const KycSubmittedScreen(),
  'KYC rejected': () => const KycRejectedScreen(),
  'KYC approved': () => const KycApprovedScreen(),
  'Home': () => const HomeScreen(),
  'Wallet': () => const WalletScreen(),
  'Send money': () => const TransferScreen(),
  'Transfer sent': () => const TransferSuccessScreen(),
  'Pay bills': () => const BillsScreen(),
  'Bill payment': () => BillPayScreen(bill: demoBills.first),
  'Bill paid': () => BillSuccessScreen(bill: demoBills.first, amount: 12500),
  'Transactions': () => const ActivityScreen(),
  'Virtual card': () => const CardScreen(),
  'Profile': () => const ProfileScreen(),
  'Notifications': () => const NotificationsScreen(),
  'Language': () => const LanguageScreen(),
  'Change PIN': () => const ChangePinScreen(),
  'Autopay': () => const AutopayPage(),
  'Add money': () => const TopUpScreen(),
  'Fund card': () => const TopUpScreen(usd: true),
};

/// flutter_test renders text with the Ahem font (every glyph is a full em
/// square), which gives unrealistic widths. The test theme uses Verdana, a
/// deliberately wide system font, so any overflow that Manrope/Bricolage could
/// trigger also shows up here. google_fonts is not used: it needs network access.
const _testFontFamily = 'KpTestSans';

Future<void> _loadRealisticFonts() async {
  final regular = _fontFile([
    r'C:\Windows\Fonts\verdana.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
  ]);
  final bold = _fontFile([
    r'C:\Windows\Fonts\verdanab.ttf',
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

  for (final entry in _screens.entries) {
    testWidgets('renders ${entry.key} without layout errors', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _testTheme(),
          home: Material(
            color: KpColors.canvas,
            child: SizedBox(width: 390, height: 844, child: entry.value()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  }
}
