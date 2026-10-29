import 'package:flutter/material.dart';

import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import 'account_entry_screen.dart';
import 'help_screens.dart';
import 'secure_account_screen.dart';

/// 10 — Confirm device change.
class DeviceConfirmScreen extends StatelessWidget {
  const DeviceConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const KpScreenTitle(
          'Confirm device change',
          'You’re about to sign in to this device for the first time. Check the details before continuing.',
        ),
        const SizedBox(height: 18),
        const _DeviceCard(),
        const SizedBox(height: 10),
        KpTextLink(
          'View full device details',
          icon: Icons.info_outline_rounded,
          onTap: () => kpOpen(
            context,
            const DeviceDetailsScreen(),
            title: 'Device details',
            step: 11,
          ),
        ),
        const SizedBox(height: 12),
        const KpTip(
          tone: KpTipTone.warning,
          child: Text(
            'If this wasn’t you, cancel and secure your account immediately.',
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Confirm & continue',
          icon: Icons.verified_user_rounded,
          onTap: () => kpOpen(
            context,
            const DeviceSuccessScreen(),
            title: 'Device changed',
            step: 12,
          ),
        ),
        const SizedBox(height: 8),
        KpTextLink(
          'This wasn’t me',
          color: KpColors.danger,
          onTap: () => kpOpen(
            context,
            const SecureAccountScreen(),
            title: 'Secure your account',
            step: 20,
          ),
        ),
        KpTextLink(
          'Cancel',
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

/// 11 — Device details, expanded.
class DeviceDetailsScreen extends StatelessWidget {
  const DeviceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpSimpleHeader(
        title: 'Device details',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const SizedBox(height: 4),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'If these details look unfamiliar, report the device and contact support.',
          ),
        ),
        const SizedBox(height: 14),
        const KpDetailCard(
          rows: [
            KpDetailRow('Device model', 'iPhone 15 Pro'),
            KpDetailRow('OS version', 'iOS 17.5.1'),
            KpDetailRow('App version', 'KumPay 1.0.0'),
            KpDetailRow('City, country', 'Douala, Cameroon'),
            KpDetailRow('IP address', '192.168.1.1'),
            KpDetailRow('Approx. location time', '24 May, 09:41'),
            KpDetailRow('Browser / runtime', 'Native iOS'),
          ],
        ),
        const SizedBox(height: 18),
        KpButton(
          label: 'Report this device',
          style: KpButtonStyle.outline,
          icon: Icons.flag_outlined,
          onTap: () => kpOpen(
            context,
            const HelpScreen(),
            title: 'Contact support',
            step: 14,
          ),
        ),
        const SizedBox(height: 10),
        KpButton(
          label: 'Remove device',
          style: KpButtonStyle.soft,
          icon: Icons.phonelink_erase_rounded,
          onTap: () => _showRemoveSheet(context),
        ),
      ],
    );
  }

  void _showRemoveSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
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
                child: KpStateIcon(type: KpStateIconType.danger, size: 62),
              ),
              const SizedBox(height: 14),
              Text(
                'Remove this device?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'The session will end and you’ll need to verify your phone again to sign in on this device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 18),
              KpButton(
                label: 'Remove device',
                style: KpButtonStyle.danger,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).maybePop();
                },
              ),
              const SizedBox(height: 4),
              KpTextLink(
                'Keep device',
                color: KpColors.muted,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 12 — Device changed successfully.
class DeviceSuccessScreen extends StatelessWidget {
  const DeviceSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KpColors.primary,
      child: Column(
        children: [
          const KpStatusBar(onDark: true),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  KpSuccessHero(
                    title: 'Device changed successfully!',
                    body:
                        'You can now use this device to access your KumPay account.',
                    compact: true,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    color: KpColors.canvas,
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _DeviceCard(),
                        const SizedBox(height: 12),
                        const KpTip(
                          tone: KpTipTone.success,
                          child: Text(
                            'For your security, you may be signed out from your previous device.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        KpButton(
                          label: 'Go to home',
                          style: KpButtonStyle.success,
                          onTap: () => kpBackToStart(context),
                        ),
                        KpTextLink(
                          'Back to home',
                          color: KpColors.muted,
                          onTap: () => kpBackToStart(context),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const KpHomeIndicator(),
        ],
      ),
    );
  }
}

/// 13 — Logged-out notice.
class LoggedOutNoticeScreen extends StatelessWidget {
  const LoggedOutNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: const KpAuthHeader(),
      children: [
        const SizedBox(height: 20),
        const Center(child: KpStateIcon(type: KpStateIconType.info, size: 86)),
        const SizedBox(height: 18),
        Text(
          'You may be signed out elsewhere',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 8),
        Text(
          'For security, active sessions on other devices may end. Sign in again on those devices if needed.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 22),
        const KpTip(
          tone: KpTipTone.success,
          child: Text(
            'Tip: enable biometrics on this device for faster, safer access next time.',
          ),
        ),
        const SizedBox(height: 22),
        KpButton(
          label: 'Go to login',
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

class _DeviceCard extends StatelessWidget {
  const _DeviceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.lg),
        border: Border.all(color: KpColors.line),
        boxShadow: KpShadows.card,
      ),
      child: const Column(
        children: [
          _DeviceItem(
            icon: Icons.phone_iphone_rounded,
            label: 'Device',
            value: 'iPhone 15 Pro',
            sub: 'iOS 17.5.1',
          ),
          Divider(color: KpColors.line),
          _DeviceItem(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'Douala, Cameroon',
            sub: 'IP: 192.168.1.1',
          ),
          Divider(color: KpColors.line),
          _DeviceItem(
            icon: Icons.schedule_rounded,
            label: 'Date & time',
            value: '24 May 2026 · 09:41 AM',
          ),
        ],
      ),
    );
  }
}

class _DeviceItem extends StatelessWidget {
  const _DeviceItem({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: KpColors.softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: KpColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.muted,
                        fontSize: 8.5,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    sub!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 9,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
