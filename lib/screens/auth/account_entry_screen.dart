import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import 'registration_screen.dart';
import 'state_screens.dart';

/// 01 — Login / phone entry.
class AccountEntryScreen extends StatefulWidget {
  const AccountEntryScreen({super.key});

  @override
  State<AccountEntryScreen> createState() => _AccountEntryScreenState();
}

class _AccountEntryScreenState extends State<AccountEntryScreen> {
  final _phone = TextEditingController(text: '677 12 34 56');

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      soft: true,
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const KpScreenTitle(
          'Welcome back',
          'Sign in with your phone number. We will send a one-time code to verify it is you.',
        ),
        const SizedBox(height: 6),
        const Center(child: KpDeviceIllustration(size: 142)),
        const SizedBox(height: 4),
        KpPhoneField(
          controller: _phone,
          label: 'Phone number',
          hint: '677 12 34 56',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        KpButton(
          label: 'Send OTP',
          icon: Icons.arrow_forward_rounded,
          onTap: () => kpOpen(
            context,
            const SendingOtpScreen(),
            title: 'Sending OTP',
            step: 17,
            note: 'Loading state while the code is delivered',
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text:
                'A 6-digit code will be sent to the phone number registered on your KumPay account. ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.muted,
                  fontSize: 9.5,
                  height: 1.5,
                ),
            children: [
              TextSpan(
                text: maskPhone(),
                style: const TextStyle(
                  color: KpColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'New to KumPay?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 10,
                  ),
            ),
            const SizedBox(width: 3),
            KpTextLink(
              'Create an account',
              onTap: () => kpOpen(
                context,
                const RegistrationScreen(),
                title: 'Registration',
                note: 'New client onboarding',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const _SecurityBadge(),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 15, color: KpColors.primary),
          const SizedBox(width: 7),
          Text(
            'Your security is our priority',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: KpColors.ink2,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
