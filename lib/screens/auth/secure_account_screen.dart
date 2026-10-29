import 'package:flutter/material.dart';

import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'account_entry_screen.dart';
import 'help_screens.dart';

/// 20 — Secure your account after an unrecognised device change.
class SecureAccountScreen extends StatelessWidget {
  const SecureAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 10),
        const Center(
            child: KpStateIcon(type: KpStateIconType.warning, size: 88)),
        const SizedBox(height: 18),
        Text(
          'Secure your account',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'If you didn’t request a device change, act now. Freezing your account blocks new sign-ins and payments.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
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
                'What happens next',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
              ),
              const SizedBox(height: 9),
              const KpBulletList(
                items: [
                  'Your account is frozen immediately.',
                  'All active sessions are signed out.',
                  'Our support team contacts you to restore access.',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const KpTip(
          tone: KpTipTone.warning,
          child: Text(
            'Never share your OTP or PIN with anyone, even someone claiming to be from KumPay.',
          ),
        ),
        const SizedBox(height: 20),
        KpButton(
          label: 'Freeze my account',
          style: KpButtonStyle.danger,
          icon: Icons.lock_rounded,
          onTap: () => _showFreezeSheet(context),
        ),
        const SizedBox(height: 8),
        KpButton(
          label: 'Contact support',
          style: KpButtonStyle.outline,
          icon: Icons.support_agent_rounded,
          onTap: () => kpOpen(
            context,
            const HelpScreen(),
            title: 'Contact support',
            step: 14,
          ),
        ),
      ],
    );
  }

  void _showFreezeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: KpStateIcon(type: KpStateIconType.lock, size: 62),
              ),
              const SizedBox(height: 14),
              Text(
                'Account frozen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your account is now frozen. Our support team will contact you on your registered number within 24 hours.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 18),
              KpButton(
                label: 'Back to login',
                style: KpButtonStyle.success,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  kpOpen(
                    context,
                    const AccountEntryScreen(),
                    title: 'Login',
                    step: 1,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
