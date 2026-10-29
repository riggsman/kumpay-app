import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/support/support_repository.dart';
import '../../features/support/support_page.dart';
import '../../preview/preview_page.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import 'account_entry_screen.dart';
import 'state_screens.dart';

/// 14 — Help / contact support.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpSimpleHeader(
        title: 'Need help?',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpScreenTitle(
          'We’re here for you',
          'Contact our support team if you didn’t make this request or need help with your account.',
        ),
        const SizedBox(height: 18),
        if ((AuthScope.maybeOf(context)?.sessionToken ?? '').isNotEmpty) ...[
          KpButton(
            label: 'Send a request',
            icon: Icons.support_agent_rounded,
            onTap: () {
              final token = AuthScope.read(context).sessionToken!;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SupportPage(
                    repository: SupportRepository(baseUrl: kApiBase, token: token),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],
        KpContactTile(
          icon: Icons.call_outlined,
          title: 'Call support',
          subtitle: '+237 690 00 00 00 · 24/7',
          onTap: () => _toast(context, 'Calling KumPay support…'),
        ),
        const SizedBox(height: 9),
        KpContactTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          subtitle: 'support@kumpay.cm',
          onTap: () => _toast(context, 'Opening your email app…'),
        ),
        const SizedBox(height: 9),
        KpContactTile(
          icon: Icons.forum_outlined,
          title: 'Live chat',
          subtitle: 'Average reply under 2 minutes',
          onTap: () => _toast(context, 'Connecting you to live chat…'),
        ),
        const SizedBox(height: 18),
        const KpTip(
          tone: KpTipTone.warning,
          child: Text(
            'KumPay staff will never ask for your OTP, PIN or password. Keep these private.',
          ),
        ),
        const SizedBox(height: 10),
        KpTextLink(
          'How does device verification work?',
          icon: Icons.help_outline_rounded,
          align: TextAlign.left,
          onTap: () => kpOpen(
            context,
            const SecurityTipsScreen(),
            title: 'Info & security tips',
            step: 15,
          ),
        ),
        const SizedBox(height: 4),
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

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KpColors.primary,
      ),
    );
  }
}

/// 15 — Info panels & tips.
class SecurityTipsScreen extends StatelessWidget {
  const SecurityTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const KpScreenTitle(
          'Stay protected',
          'Quick notes on why we verify devices and how you can keep your money safe.',
        ),
        const SizedBox(height: 16),
        const KpInfoPanel(
          title: 'Why do we do this?',
          icon: Icons.shield_outlined,
          tone: KpTipTone.info,
          child: Text(
            'We verify your identity when you sign in from a new device to prevent someone else from accessing your account.',
          ),
        ),
        const SizedBox(height: 10),
        const KpInfoPanel(
          title: 'Tips to keep your account secure',
          icon: Icons.lightbulb_outline_rounded,
          tone: KpTipTone.gold,
          child: KpBulletList(
            items: [
              'Never share your OTP or transaction PIN.',
              'Always sign out of public or shared devices.',
              'Enable biometric login on your personal phone.',
              'Report unexpected device changes to support.',
            ],
          ),
        ),
        const SizedBox(height: 10),
        KpInfoPanel(
          title: 'Need help?',
          icon: Icons.support_agent_rounded,
          tone: KpTipTone.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact our support team if you didn’t make this request. We can freeze your account while we investigate.',
              ),
              const SizedBox(height: 4),
              KpTextLink(
                'Contact support',
                icon: Icons.arrow_forward_rounded,
                align: TextAlign.left,
                onTap: () => kpOpen(
                  context,
                  const HelpScreen(),
                  title: 'Contact support',
                  step: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 21 — Invalid account / phone number.
class InvalidAccountScreen extends StatefulWidget {
  const InvalidAccountScreen({super.key});

  @override
  State<InvalidAccountScreen> createState() => _InvalidAccountScreenState();
}

class _InvalidAccountScreenState extends State<InvalidAccountScreen> {
  final _phone = TextEditingController(text: '000 00 00 00');

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
          'Change device',
          'For your security, we’ll verify your account before you can sign in on this device.',
        ),
        const SizedBox(height: 20),
        const KpFieldLabel('Enter your phone number'),
        Container(
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.danger),
            boxShadow: [
              BoxShadow(
                color: KpColors.danger.withValues(alpha: 0.12),
                blurRadius: 0,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.phone_outlined,
                  size: 20, color: KpColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: KpColors.danger,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const KpInlineError(
          'We couldn’t find that number. Check it and try again.',
        ),
        const SizedBox(height: 18),
        KpButton(
          label: 'Send OTP',
          onTap: () => kpOpen(
            context,
            const SendingOtpScreen(),
            title: 'Sending OTP',
            step: 17,
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text:
                'A one-time password will be sent to your registered number ending in ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.muted,
                  fontSize: 9.5,
                  height: 1.5,
                ),
            children: const [
              TextSpan(
                text: '***456',
                style:
                    TextStyle(color: KpColors.ink, fontWeight: FontWeight.w800),
              ),
              TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Container(
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
        ),
      ],
    );
  }
}

/// 22 — Network error.
class NetworkErrorScreen extends StatelessWidget {
  const NetworkErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 26),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: KpColors.warningSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 38,
              color: KpColors.warning,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Connection problem',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'We couldn’t reach KumPay. Check your internet connection and try again.',
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
            'If you’re on mobile data, check that data is enabled and try switching to Wi-Fi.',
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        KpTextLink(
          'Contact support',
          color: KpColors.muted,
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
}
