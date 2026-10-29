import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import '../kyc/kyc_screens.dart';
import 'change_phone_screen.dart';
import 'otp_sent_screen.dart';
import 'state_screens.dart';

/// OTP verification states.
///
/// Used by artboards 04 (default), 05 (keyboard visible),
/// 06 (incorrect) and 19 (resend ready).
enum OtpMode { normal, keyboard, incorrect, resendReady }

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
    super.key,
    this.mode = OtpMode.normal,
    this.title = 'Verify OTP',
    this.description =
        'Enter the 6-digit code sent to your phone number ending in ***456.',
    this.maskedPhone,
    this.forRegistration = false,
  });

  final OtpMode mode;
  final String title;
  final String description;
  final String? maskedPhone;
  final bool forRegistration;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  late final TextEditingController _otp = TextEditingController(
    text: widget.mode == OtpMode.incorrect ? '482190' : '',
  );

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _append(String digit) {
    if (_otp.text.length >= 6) return;
    _otp.text = '${_otp.text}$digit';
  }

  void _backspace() {
    if (_otp.text.isEmpty) return;
    _otp.text = _otp.text.substring(0, _otp.text.length - 1);
  }

  void _verify() {
    if (widget.mode == OtpMode.incorrect) {
      kpOpen(
        context,
        const DeviceFailedScreen(),
        title: 'Device change failed',
        step: 16,
      );
      return;
    }

    if (widget.forRegistration) {
      kpOpen(
        context,
        const KycIntroScreen(),
        title: 'Identity verification',
        note: 'Account created · KYC unverified',
      );
      return;
    }

    kpOpen(
      context,
      const VerifyingOtpScreen(),
      title: 'Verifying OTP',
      step: 18,
    );
  }

  void _resend() {
    kpOpen(
      context,
      const OtpSentScreen(resent: true),
      title: 'OTP resent',
      step: 9,
    );
  }

  @override
  Widget build(BuildContext context) {
    final incorrect = widget.mode == OtpMode.incorrect;
    final keyboard = widget.mode == OtpMode.keyboard;
    final resendReady = widget.mode == OtpMode.resendReady;
    final masked = widget.maskedPhone ?? maskPhone();

    final content = <Widget>[
      KpScreenTitle(widget.title, widget.description),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: KpColors.surface,
          borderRadius: BorderRadius.circular(KpRadius.md),
          border: Border.all(color: KpColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: KpColors.softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_iphone_rounded,
                  size: 15, color: KpColors.primary),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code sent to',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 8.5,
                        ),
                  ),
                  Text(
                    masked,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
            ),
            KpTextLink(
              'Change',
              onTap: () => kpOpen(
                context,
                const ChangePhoneScreen(),
                title: 'Change phone number',
                step: 2,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      KpOtpBoxes(
        controller: _otp,
        autofocus: !keyboard,
        error: incorrect,
        showSystemKeyboard: !keyboard,
      ),
      if (incorrect) ...[
        const SizedBox(height: 10),
        const KpInlineError(
          'Incorrect code. Please check the 6 digits and try again.',
        ),
      ],
      const SizedBox(height: 14),
      if (resendReady)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn’t get a code? ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 10,
                  ),
            ),
            KpTextLink('Resend OTP', onTap: _resend),
          ],
        )
      else
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: KpColors.surface,
              borderRadius: BorderRadius.circular(KpRadius.pill),
              border: Border.all(color: KpColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: KpColors.muted),
                const SizedBox(width: 5),
                Text(
                  'Resend code in ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.muted,
                        fontSize: 9.5,
                      ),
                ),
                Text(
                  resendReady ? '00:00' : '00:28',
                  style: const TextStyle(
                    color: KpColors.primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 14),
      const KpTip(
        tone: KpTipTone.info,
        child: Text(
          'Never share this code with anyone. KumPay staff will never ask for your OTP.',
        ),
      ),
    ];

    if (keyboard) {
      return KpPage(
        header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KpButton(label: 'Verify OTP', onTap: _verify),
            const SizedBox(height: 4),
            KpKeypad(onKey: _append, onBackspace: _backspace),
          ],
        ),
        children: content,
      );
    }

    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KpButton(
            label: 'Verify OTP',
            onTap: _verify,
          ),
          if (resendReady)
            KpTextLink(
              'Resend OTP',
              color: KpColors.muted,
              onTap: _resend,
            )
          else if (!incorrect)
            KpTextLink(
              'Show keyboard variant',
              color: KpColors.muted,
              onTap: () => kpOpen(
                context,
                const OtpVerifyScreen(mode: OtpMode.keyboard),
                title: 'OTP · keyboard visible',
                step: 5,
              ),
            )
          else
            KpTextLink(
              'Resend OTP',
              color: KpColors.muted,
              onTap: _resend,
            ),
        ],
      ),
      children: content,
    );
  }
}
