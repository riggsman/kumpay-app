import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'otp_verify_screen.dart';

/// 03 — OTP sent confirmation. Also used for 09 — resend confirmation.
class OtpSentScreen extends StatelessWidget {
  const OtpSentScreen({
    super.key,
    this.resent = false,
    this.maskedPhone,
    this.forRegistration = false,
  });

  final bool resent;
  final String? maskedPhone;
  final bool forRegistration;

  @override
  Widget build(BuildContext context) {
    final masked = maskedPhone ?? maskPhone();

    return KpPage(
      soft: !resent,
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 16),
        Center(
          child: KpStateIcon(
            type: resent ? KpStateIconType.success : KpStateIconType.info,
            size: 88,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          resent ? 'OTP resent' : 'OTP sent',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: resent
                ? 'A new 6-digit code has been sent to '
                : 'A 6-digit code was sent to ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KpColors.muted,
                  fontSize: 11.5,
                  height: 1.55,
                ),
            children: [
              TextSpan(
                text: masked,
                style: const TextStyle(
                  color: KpColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '. It expires in 5 minutes.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
                  '00:30',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const KpTip(
          tone: KpTipTone.gold,
          child: Text(
            'Didn’t receive it? Check that your number is correct. SMS and WhatsApp delivery can take up to 60 seconds.',
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Enter OTP',
          onTap: () => kpOpen(
            context,
            OtpVerifyScreen(forRegistration: forRegistration),
            title: 'Verify OTP',
            step: 4,
          ),
        ),
        const SizedBox(height: 4),
        KpTextLink(
          resent ? 'Back to login' : 'Resend now',
          color: KpColors.muted,
          onTap: resent
              ? () => kpBackToStart(context)
              : () => kpOpen(
                    context,
                    OtpSentScreen(
                      resent: true,
                      forRegistration: forRegistration,
                    ),
                    title: 'OTP resent',
                    step: 9,
                  ),
        ),
      ],
    );
  }
}
