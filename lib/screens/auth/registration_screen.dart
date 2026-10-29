import 'package:flutter/material.dart';

import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'account_entry_screen.dart';
import 'otp_sent_screen.dart';

/// Client registration — name, phone and email.
///
/// The backend creates the account after the phone OTP is verified and starts
/// it in the `unverified` KYC state.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _accepted = true;
  bool _marketing = false;
  bool _showErrors = false;

  @override
  Widget build(BuildContext context) {
    return KpPage(
      soft: true,
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const KpScreenTitle(
          'Create your account',
          'Join KumPay in under a minute. We’ll verify your phone number with a one-time code.',
        ),
        const SizedBox(height: 18),
        const KpTextField(
          label: 'Full name',
          hint: 'Aïcha Ngono',
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        const KpPhoneField(),
        const SizedBox(height: 14),
        const KpTextField(
          label: 'Email address',
          hint: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          optional: 'optional',
        ),
        const SizedBox(height: 4),
        Text(
          'A verified email can receive OTP codes and receipts.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KpColors.muted,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 16),
        _ConsentRow(
          checked: _accepted,
          onTap: () => setState(() => _accepted = !_accepted),
          label: const TextSpan(
            text: 'I agree to the ',
            children: [
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(
                  color: KpColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: KpColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _ConsentRow(
          checked: _marketing,
          onTap: () => setState(() => _marketing = !_marketing),
          label: const TextSpan(
            text: 'Send me product updates and offers (optional).',
          ),
        ),
        if (_showErrors && !_accepted) ...[
          const SizedBox(height: 6),
          const KpInlineError(
            'Please accept the Terms of Service and Privacy Policy to continue.',
          ),
        ],
        const SizedBox(height: 16),
        const KpTip(
          tone: KpTipTone.success,
          child: Text(
            'KumPay never asks for your PIN or OTP by phone, SMS or WhatsApp.',
          ),
        ),
        const SizedBox(height: 18),
        KpButton(
          label: 'Create account',
          onTap: () {
            if (!_accepted) {
              setState(() => _showErrors = true);
              return;
            }
            kpOpen(
              context,
              const OtpSentScreen(forRegistration: true),
              title: 'Verify your number',
              step: 3,
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 10,
                  ),
            ),
            KpTextLink(
              'Log in',
              onTap: () => kpOpen(
                context,
                const AccountEntryScreen(),
                title: 'Login',
                step: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.checked,
    required this.onTap,
    required this.label,
  });

  final bool checked;
  final VoidCallback onTap;
  final InlineSpan label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked ? KpColors.primary : KpColors.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: checked ? KpColors.primary : KpColors.line,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.ink2,
                      fontSize: 9.5,
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
