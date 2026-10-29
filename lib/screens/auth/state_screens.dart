import 'package:flutter/material.dart';

import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'account_entry_screen.dart';
import 'device_screens.dart';
import 'help_screens.dart';
import 'otp_sent_screen.dart';
import 'otp_verify_screen.dart';

/// 07 — Code expired.
class OtpExpiredScreen extends StatelessWidget {
  const OtpExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 24),
        const Center(
            child: KpStateIcon(type: KpStateIconType.warning, size: 88)),
        const SizedBox(height: 18),
        Text(
          'Code expired',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Your one-time code has expired. Request a new one to continue signing in.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 22),
        const KpTip(
          tone: KpTipTone.gold,
          child: Text(
            'For your security, each code can only be used once and expires after 5 minutes.',
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Resend OTP',
          onTap: () => kpOpen(
            context,
            const OtpSentScreen(resent: true),
            title: 'OTP resent',
            step: 9,
          ),
        ),
        KpTextLink(
          'Back to login',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const AccountEntryScreen(),
            title: 'Login',
            step: 1,
          ),
        ),
      ],
    );
  }
}

/// 08 — Too many attempts / temporarily locked.
class OtpLockedScreen extends StatelessWidget {
  const OtpLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 24),
        const Center(child: KpStateIcon(type: KpStateIconType.lock, size: 88)),
        const SizedBox(height: 18),
        Text(
          'Temporarily locked',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Too many incorrect attempts. Try again in 15 minutes or contact support for help.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 18, color: KpColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Locked until 09:56',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
              const KpPill(label: '15 min', tone: KpPillTone.gold),
            ],
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Contact support',
          onTap: () => kpOpen(
            context,
            const HelpScreen(),
            title: 'Contact support',
            step: 14,
          ),
        ),
        KpTextLink(
          'Back to login',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const AccountEntryScreen(),
            title: 'Login',
            step: 1,
          ),
        ),
      ],
    );
  }
}

/// 17 — Sending OTP.
class SendingOtpScreen extends StatelessWidget {
  const SendingOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      scroll: false,
      centerBody: true,
      children: [
        const _Loader(),
        const SizedBox(height: 24),
        Text(
          'Sending OTP…',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'We’re sending a 6-digit code to your registered phone number ending in ***456.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 22),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Delivery is attempted over SMS, then WhatsApp, then email. Keep this screen open.',
          ),
        ),
        const SizedBox(height: 20),
        KpTextLink(
          'Continue to code sent',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const OtpSentScreen(),
            title: 'OTP sent',
            step: 3,
          ),
        ),
      ],
    );
  }
}

/// 18 — Verifying OTP.
class VerifyingOtpScreen extends StatelessWidget {
  const VerifyingOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: const KpAuthHeader(),
      scroll: false,
      centerBody: true,
      children: [
        const _Loader(),
        const SizedBox(height: 24),
        Text(
          'Verifying…',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we confirm your code and prepare this device.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded,
                size: 14, color: KpColors.success),
            const SizedBox(width: 6),
            Text(
              'Secured with 256-bit encryption',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: KpColors.success,
                    fontSize: 9,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        KpTextLink(
          'Continue',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const DeviceConfirmScreen(),
            title: 'Confirm device change',
            step: 10,
          ),
        ),
      ],
    );
  }
}

/// 16 — Device change failed.
class DeviceFailedScreen extends StatelessWidget {
  const DeviceFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 18),
        const Center(
            child: KpStateIcon(type: KpStateIconType.danger, size: 86)),
        const SizedBox(height: 18),
        Text(
          'Device change failed',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'We couldn’t verify your request. Please try again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Possible reasons',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
              ),
              const SizedBox(height: 9),
              const KpBulletList(
                items: [
                  'The code you entered was incorrect.',
                  'The code expired before it was used.',
                  'Too many verification attempts were made.',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Try again',
          onTap: () => kpOpen(
            context,
            const OtpVerifyScreen(),
            title: 'Verify OTP',
            step: 4,
          ),
        ),
        const SizedBox(height: 8),
        KpButton(
          label: 'Resend OTP',
          style: KpButtonStyle.outline,
          onTap: () => kpOpen(
            context,
            const OtpSentScreen(resent: true),
            title: 'OTP resent',
            step: 9,
          ),
        ),
        KpTextLink(
          'Back to login',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const AccountEntryScreen(),
            title: 'Login',
            step: 1,
          ),
        ),
      ],
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 78,
        height: 78,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: KpColors.softGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: KpColors.primary,
                backgroundColor: Color(0xFFD8E5DC),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: KpColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 15, color: KpColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
