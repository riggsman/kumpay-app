import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/demo.dart';
import '../../data/cards/cards_repository.dart';
import '../../data/notifications/notifications_repository.dart';
import '../../data/kyc/kyc_repository.dart';
import '../../features/cards/cards_page.dart';
import '../../features/feature_flags/app_feature.dart';
import '../../features/feature_flags/platform_alert.dart';
import '../../features/kyc/kyc_page.dart';
import '../../features/services/platform_service.dart';
import '../../features/services/service_pay_page.dart';
import '../../features/money/live_money.dart';
import '../../preview/preview_page.dart';
import '../../state/auth_scope.dart';
import '../../state/feature_flags_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_shell.dart';
import '../bills/bills_screen.dart';
import '../cards/card_screen.dart';
import '../kyc/kyc_screens.dart';
import '../profile/profile_screen.dart';
import '../wallet/activity_screen.dart';
import '../wallet/top_up_screen.dart';
import '../wallet/transfer_screen.dart';
import '../wallet/wallet_screen.dart';

/// 23 — Home dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthScope.maybeOf(context)?.user;
    final name = signedIn?.name ?? demoUser.name;
    final initials = _initials(name);
    final deposit = FeatureFlagsScope.enabled(context, AppFeature.deposit);
    final send = FeatureFlagsScope.enabled(context, AppFeature.send);
    final bills = FeatureFlagsScope.enabled(context, AppFeature.bills);
    final eneo = FeatureFlagsScope.enabled(context, AppFeature.eneo);
    final snapshot = FeatureFlagsScope.maybeOf(context)?.snapshot;
    final platformServices = bills
        ? (snapshot?.services ?? const <PlatformService>[])
        : const <PlatformService>[];
    final alert = snapshot?.alert;
    void openDeposit() => kpOpen(
          context,
          const TopUpScreen(),
          title: 'Add money',
        );
    return KpPage(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
      header: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: KpColors.gradientGold,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: KpColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: KpColors.muted, fontSize: 9),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          _BellButton(token: AuthScope.maybeRead(context)?.sessionToken),
        ],
      ),
      bottomNav: kpAppNav(context, active: KpTab.home),
      children: [
        WalletAmount(
          fallback: formatXaf(demoUser.xaf),
          builder: (context, amount) => KpBalanceCard(
            amount: amount,
            showPrimary: deposit,
            showSecondary: send,
            onPrimary: deposit ? openDeposit : null,
            onSecondary: send
                ? () => kpOpen(
                      context,
                      const TransferScreen(),
                      title: 'Send money',
                      step: 25,
                    )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        KpKycBanner(
          verified: signedIn == null || signedIn.kyc == 'approved',
          subtitle: signedIn == null ? null : _kycSubtitle(signedIn.kyc),
          onTap: () {
            final token = AuthScope.maybeRead(context)?.sessionToken;
            if (token != null && token.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => KycPage(
                    repository: KycRepository(baseUrl: kApiBase, token: token),
                  ),
                ),
              );
              return;
            }
            kpOpen(
              context,
              const KycApprovedScreen(),
              title: 'KYC approved',
              step: 0,
            );
          },
        ),
        const SizedBox(height: 16),
        KpSectionHeader(
          title: 'Services',
          action: 'See all',
          onAction: () => kpOpen(
            context,
            const WalletScreen(),
            title: 'All services',
            step: 24,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (deposit)
              Expanded(
                child: KpServiceTile(
                  label: 'Add money',
                  icon: Icons.add_rounded,
                  onTap: openDeposit,
                ),
              ),
            if (send)
              Expanded(
                child: KpServiceTile(
                  label: 'Send',
                  icon: Icons.north_east_rounded,
                  tone: KpServiceTone.gold,
                  onTap: () => kpOpen(
                    context,
                    const TransferScreen(),
                    title: 'Send money',
                    step: 25,
                  ),
                ),
              ),
            if (bills)
              Expanded(
                child: KpServiceTile(
                  label: 'Pay bills',
                  icon: Icons.receipt_long_outlined,
                  tone: KpServiceTone.info,
                  onTap: () => kpOpen(
                    context,
                    const BillsScreen(),
                    title: 'Pay bills',
                    step: 27,
                  ),
                ),
              ),
            Expanded(
              child: KpServiceTile(
                label: 'Card',
                icon: Icons.credit_card_rounded,
                tone: KpServiceTone.neutral,
                onTap: () {
                  final token = AuthScope.maybeRead(context)?.sessionToken;
                  if (token != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CardsPage(
                          repository: CardsRepository(
                            baseUrl: kApiBase,
                            token: token,
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  kpOpen(
                    context,
                    const CardScreen(),
                    title: 'Virtual card',
                    step: 30,
                  );
                },
              ),
            ),
          ],
        ),
        if (platformServices.isNotEmpty) ...[
          const SizedBox(height: 14),
          const KpSectionHeader(title: 'New services'),
          const SizedBox(height: 8),
          for (final service in platformServices.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: KpColors.surface,
                borderRadius: BorderRadius.circular(KpRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(KpRadius.md),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ServicePayPage(service: service),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        ServiceLogo(service: service, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: KpColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 14),
        WalletAmount(
          fallback: '\$120.50',
          usd: true,
          builder: (context, amount) => KpMiniAccountTile(
            title: 'USD wallet',
            subtitle: 'Virtual card funding',
            amount: amount,
            icon: Icons.attach_money_rounded,
            tone: KpServiceTone.gold,
          ),
        ),
        const SizedBox(height: 8),
        KpMiniAccountTile(
          title: 'Savings',
          subtitle:
              signedIn == null ? 'Locked until 12 Dec' : 'Not available yet',
          amount: signedIn == null ? '80 000 FCFA' : '—',
          icon: Icons.savings_outlined,
          tone: KpServiceTone.info,
        ),
        const SizedBox(height: 16),
        KpSectionHeader(
          title: 'Recent activity',
          action: 'View all',
          onAction: () => kpOpen(
            context,
            const ActivityScreen(),
            title: 'Transaction history',
            step: 29,
          ),
        ),
        const SizedBox(height: 4),
        const LiveActivityList(limit: 4),
        const SizedBox(height: 6),
        if (alert != null && alert.enabled)
          _GoldPromo(
            title: alert.title,
            message: alert.message,
            onTap: _alertAction(context, alert, bills: bills, send: send),
          )
        else if (alert == null && signedIn == null && eneo && bills)
          _GoldPromo(
            title: 'Zero fees on ENEO this week',
            message: 'Pay any prepaid meter before Sunday.',
            onTap: () => kpOpen(
              context,
              const BillsScreen(),
              title: 'Pay bills',
              step: 27,
            ),
          ),
      ],
    );
  }
}

class _BellButton extends StatefulWidget {
  const _BellButton({required this.token});

  final String? token;

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton> {
  int? _unread;

  bool get _signedIn => widget.token != null && widget.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _BellButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _load();
  }

  Future<void> _load() async {
    if (!_signedIn) {
      if (mounted) setState(() => _unread = null);
      return;
    }
    try {
      final count = await NotificationsRepository(
        baseUrl: kApiBase,
        token: widget.token!,
      ).unreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {
      if (mounted) setState(() => _unread = null);
    }
  }

  Future<void> _open() async {
    if (!_signedIn) {
      kpOpen(
        context,
        const NotificationsScreen(),
        title: 'Notifications',
        step: 0,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final showDot = !_signedIn || _unread == null || _unread! > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        KpIconButton(icon: Icons.notifications_none_rounded, onTap: _open),
        if (showDot)
          Positioned(
            right: 9,
            top: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: KpColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: KpColors.canvas, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'KP';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _kycSubtitle(String kyc) {
  return switch (kyc) {
    'approved' => 'Identity verified',
    'pending' || 'in_progress' => 'Review in progress',
    'rejected' => 'Verification was not approved',
    _ => 'Identity not verified yet',
  };
}

VoidCallback? _alertAction(
  BuildContext context,
  PlatformAlert alert, {
  required bool bills,
  required bool send,
}) {
  return switch (alert.action) {
    'bills' when bills => () => kpOpen(
          context,
          const BillsScreen(),
          title: 'Pay bills',
          step: 27,
        ),
    'wallet' => () => kpOpen(
          context,
          const WalletScreen(),
          title: 'Wallet',
          step: 24,
        ),
    'send' when send => () => kpOpen(
          context,
          const TransferScreen(),
          title: 'Send money',
          step: 25,
        ),
    _ => null,
  };
}

class _GoldPromo extends StatelessWidget {
  const _GoldPromo({
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KpRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KpColors.goldSoft,
          borderRadius: BorderRadius.circular(KpRadius.lg),
          border: Border.all(color: KpColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: KpColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 20,
                color: KpColors.primaryDark,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: KpColors.ink2, fontSize: 9.5),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: KpColors.goldDeep,
              ),
          ],
        ),
      ),
    );
  }
}
