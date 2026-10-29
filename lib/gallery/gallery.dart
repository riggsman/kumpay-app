import 'package:flutter/material.dart';

import '../data/demo.dart';
import '../preview/preview_page.dart';
import '../screens/auth/account_entry_screen.dart';
import '../screens/auth/change_phone_screen.dart';
import '../screens/auth/device_screens.dart';
import '../screens/auth/help_screens.dart';
import '../screens/auth/otp_sent_screen.dart';
import '../screens/auth/otp_verify_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/secure_account_screen.dart';
import '../screens/auth/state_screens.dart';
import '../screens/bills/bills_screen.dart';
import '../screens/cards/card_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/kyc/kyc_screens.dart';
import '../screens/profile/autopay_page.dart';
import '../screens/profile/change_pin_screen.dart';
import '../screens/profile/language_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wallet/activity_screen.dart';
import '../screens/wallet/top_up_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../theme/kp_theme.dart';
import '../widgets/kp_brand.dart';

class KpGallery extends StatelessWidget {
  const KpGallery({super.key});

  static final _groups = <_Group>[
    _Group(
      title: 'Onboarding & authentication',
      subtitle: 'Phone-first sign-in, OTP states, and new-device verification.',
      entries: [
        _Entry('01', 'Login', 'Phone entry with OTP hand-off.',
            () => const AccountEntryScreen()),
        _Entry('02', 'Change number', 'New phone number + cooldown warning.',
            () => const ChangePhoneScreen()),
        _Entry('03', 'OTP sent', 'Code delivered to the masked number.',
            () => const OtpSentScreen()),
        _Entry('04', 'Verify OTP', 'Six-digit input with resend timer.',
            () => const OtpVerifyScreen()),
        _Entry('05', 'OTP keyboard', 'In-app keypad variant.',
            () => const OtpVerifyScreen(mode: OtpMode.keyboard)),
        _Entry('06', 'Incorrect OTP', 'Inline error with retry guidance.',
            () => const OtpVerifyScreen(mode: OtpMode.incorrect)),
        _Entry('07', 'Code expired', 'Recovery after the 5-minute TTL.',
            () => const OtpExpiredScreen()),
        _Entry('08', 'Too many attempts', '15-minute lock with support path.',
            () => const OtpLockedScreen()),
        _Entry('09', 'OTP resent', 'Resend confirmation state.',
            () => const OtpSentScreen(resent: true)),
        _Entry('10', 'Confirm device', 'New-device review before sign-in.',
            () => const DeviceConfirmScreen()),
        _Entry('11', 'Device details', 'Model, IP, location and runtime.',
            () => const DeviceDetailsScreen()),
        _Entry('12', 'Device changed', 'Success state with session notice.',
            () => const DeviceSuccessScreen()),
        _Entry('13', 'Signed out elsewhere', 'Post-change session warning.',
            () => const LoggedOutNoticeScreen()),
        _Entry('14', 'Help & support', 'Phone, email and live chat.',
            () => const HelpScreen()),
        _Entry('15', 'Security tips', 'Why we verify + account safety.',
            () => const SecurityTipsScreen()),
        _Entry('16', 'Device failed', 'Failure reasons and retry.',
            () => const DeviceFailedScreen()),
        _Entry('17', 'Sending OTP', 'Delivery loading state.',
            () => const SendingOtpScreen()),
        _Entry('18', 'Verifying OTP', 'Verification loading state.',
            () => const VerifyingOtpScreen()),
        _Entry('19', 'Resend ready', 'Timer elapsed, resend enabled.',
            () => const OtpVerifyScreen(mode: OtpMode.resendReady)),
        _Entry(
            '20',
            'Secure account',
            'Freeze account after suspicious access.',
            () => const SecureAccountScreen()),
        _Entry('21', 'Invalid account', 'Rejected number + inline error.',
            () => const InvalidAccountScreen()),
        _Entry('22', 'Network error', 'Offline recovery screen.',
            () => const NetworkErrorScreen()),
      ],
    ),
    _Group(
      title: 'Registration & KYC',
      subtitle: 'Client onboarding added for the KumPay backend contract.',
      entries: [
        _Entry('R1', 'Create account', 'Name, phone, email and consent.',
            () => const RegistrationScreen()),
        _Entry('K1', 'KYC intro', 'Why verification is required.',
            () => const KycIntroScreen()),
        _Entry('K2', 'KYC form', 'Details and private document upload.',
            () => const KycFormScreen()),
        _Entry('K3', 'KYC submitted', 'Pending review and timeline.',
            () => const KycSubmittedScreen()),
        _Entry('K4', 'KYC rejected', 'Reason from compliance + resubmit.',
            () => const KycRejectedScreen()),
        _Entry('K5', 'KYC approved', 'Verified state and immutable NIU.',
            () => const KycApprovedScreen()),
      ],
    ),
    _Group(
      title: 'Core app',
      subtitle:
          'Home, wallet, transfers, bills, cards and the transaction trail.',
      entries: [
        _Entry('23', 'Home', 'Balances, services and activity.',
            () => const HomeScreen()),
        _Entry('24', 'Wallet', 'FCFA/USD wallets + linked accounts.',
            () => const WalletScreen()),
        _Entry('25', 'Send money', 'Recipient, amount and fee summary.',
            () => const TransferScreen()),
        _Entry('26', 'Transfer sent', 'Success receipt with reference.',
            () => const TransferSuccessScreen()),
        _Entry('27', 'Pay bills', 'ENEO, CAMWATER, Canal+, DStv.',
            () => const BillsScreen()),
        _Entry('28', 'Bill payment', 'Meter lookup, amount and total.',
            () => BillPayScreen(bill: demoBills.first)),
        _Entry('28b', 'Bill paid', 'Provider confirmation receipt.',
            () => BillSuccessScreen(bill: demoBills.first, amount: 12500)),
        _Entry('29', 'Transactions', 'Filterable history with summary.',
            () => const ActivityScreen()),
        _Entry('30', 'Virtual card', 'Freeze, reveal, limits and credits.',
            () => const CardScreen()),
        _Entry('31', 'Profile', 'Account, security and preferences.',
            () => const ProfileScreen()),
      ],
    ),
    _Group(
      title: 'Profile & money moves',
      subtitle: 'Everyday flows that support the core screens.',
      entries: [
        _Entry('N1', 'Notifications', 'Client alerts with read-only detail.',
            () => const NotificationsScreen()),
        _Entry('L1', 'Language', 'English, French, Pidgin, Fulfulde.',
            () => const LanguageScreen()),
        _Entry('S1', 'Change PIN', 'Current PIN → OTP → new PIN.',
            () => const ChangePinScreen()),
        _Entry('A1', 'Autopay', 'The tenant turns automatic payments on.',
            () => const AutopayPage()),
        _Entry('W1', 'Add money', 'Deposit and withdraw methods.',
            () => const TopUpScreen()),
        _Entry('C1', 'Fund card', 'USD top-up from the wallet.',
            () => const TopUpScreen(usd: true)),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KpColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GalleryHeader(),
                  const SizedBox(height: 24),
                  for (final group in _groups) ...[
                    _GroupSection(group: group),
                    const SizedBox(height: 26),
                  ],
                  _GalleryFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const KpBrand(),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: KpColors.softGreen,
                borderRadius: BorderRadius.circular(KpRadius.pill),
              ),
              child: Text(
                'MOBILE UI KIT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      letterSpacing: 0.8,
                    ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: KpColors.surface,
                borderRadius: BorderRadius.circular(KpRadius.pill),
                border: Border.all(color: KpColors.line),
              ),
              child: Text(
                '390 × 844',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 8.5,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Text(
            'A calm, secure mobile\nbanking experience.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 42,
                  height: 1.05,
                  letterSpacing: -1.4,
                ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Every client-facing flow for KumPay Cameroon — login, OTP, registration, KYC, wallet, bills, virtual cards and profile. Built with the KumPay forest-green and gold identity.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KpColors.muted,
                  fontSize: 12,
                  height: 1.6,
                ),
          ),
        ),
        const SizedBox(height: 20),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(value: '31', label: 'production artboards'),
            _StatChip(value: '+6', label: 'registration & KYC'),
            _StatChip(value: '1', label: 'shared design system'),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              colors: [
                KpColors.primaryDark,
                KpColors.primary,
                KpColors.primaryLight,
                KpColors.gold,
                KpColors.goldSoft,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group});

  final _Group group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: KpColors.gold,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              group.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: KpColors.soft,
                borderRadius: BorderRadius.circular(KpRadius.pill),
              ),
              child: Text(
                '${group.entries.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 8.5,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          group.subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KpColors.muted,
                fontSize: 10.5,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 720
                    ? 3
                    : constraints.maxWidth >= 480
                        ? 2
                        : 1;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in group.entries)
                  SizedBox(
                    width: width,
                    child: _EntryCard(entry: entry),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(KpRadius.md),
        onTap: () => kpOpen(
          context,
          entry.build(),
          title: entry.title,
          step: int.tryParse(entry.number),
          note: entry.description,
        ),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: KpColors.softGreen,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      entry.number,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: KpColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: KpColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 9,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KpColors.primary,
        borderRadius: BorderRadius.circular(KpRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 18, color: KpColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo data only. Wire the screens to /api/auth, /api/kyc, /api/cards and the wallet service before release.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFDF9EE).withValues(alpha: 0.8),
                    fontSize: 9.5,
                    height: 1.5,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'KumPay · 2026',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: KpColors.gold,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: KpColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.muted,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _Group {
  const _Group({
    required this.title,
    required this.subtitle,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final List<_Entry> entries;
}

class _Entry {
  const _Entry(this.number, this.title, this.description, this.build);

  final String number;
  final String title;
  final String description;
  final Widget Function() build;
}
