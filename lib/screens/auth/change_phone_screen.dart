import 'package:flutter/material.dart';

import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'otp_verify_screen.dart';
import 'state_screens.dart';

/// 02 — Change phone number entry.
class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpScreenTitle(
          'Change phone number',
          'Enter a different phone number. We will send a one-time code to confirm it belongs to you.',
        ),
        const SizedBox(height: 20),
        KpPhoneField(
          controller: _phone,
          label: 'New phone number',
          hint: '690 00 00 00',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        const KpTip(
          tone: KpTipTone.warning,
          child: Text(
            'Your primary number can only be changed once every 6 months. Your old number will receive a security notice after the change is confirmed.',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_iphone_rounded,
                  size: 18, color: KpColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current number',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: KpColors.muted,
                            fontSize: 9,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+237 677 12 34 56',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                    ),
                  ],
                ),
              ),
              const KpPill(label: 'Primary', tone: KpPillTone.green),
            ],
          ),
        ),
        const SizedBox(height: 26),
        KpButton(
          label: 'Send OTP to this number',
          icon: Icons.arrow_forward_rounded,
          onTap: () => kpOpen(
            context,
            const SendingOtpScreen(),
            title: 'Sending OTP',
            step: 17,
          ),
        ),
        const SizedBox(height: 6),
        KpTextLink(
          'Use my registered number',
          onTap: () => kpOpen(
            context,
            const OtpVerifyScreen(),
            title: 'Verify OTP',
            step: 4,
          ),
        ),
      ],
    );
  }
}
