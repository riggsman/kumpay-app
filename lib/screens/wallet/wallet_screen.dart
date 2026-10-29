import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/cards/cards_repository.dart';
import '../../data/demo.dart';
import '../../features/cards/cards_page.dart';
import '../../features/money/live_money.dart';
import '../../state/auth_scope.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../cards/card_screen.dart';
import 'activity_screen.dart';
import 'top_up_screen.dart';
import 'transfer_screen.dart';

/// 24 — Wallet overview.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final xaf = _tab == 0;

    return KpPage(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
      header: KpSimpleHeader(
        title: 'Wallet',
        onBack: () => Navigator.of(context).maybePop(),
        trailing: KpIconButton(
          icon: Icons.tune_rounded,
          size: 36,
          onTap: () => _showWalletSettings(context),
        ),
      ),
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      children: [
        KpSegmentedTabs(
          tabs: const ['FCFA wallet', 'USD wallet'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 12),
        WalletAmount(
          key: ValueKey(_tab),
          usd: !xaf,
          fallback: xaf ? formatXaf(demoUser.xaf) : '\$120.50',
          builder: (context, amount) => KpBalanceCard(
            amount: amount,
            label: xaf ? 'Available balance' : 'USD balance',
            account: xaf ? 'XAF wallet' : 'USD wallet',
            wallet: xaf ? 'KumPay Wallet' : 'Card funding account',
            primaryAction: 'Add money',
            secondaryAction: 'Send',
            onPrimary: () => kpOpen(
              context,
              TopUpScreen(usd: !xaf),
              title: 'Add money',
              step: 0,
            ),
            onSecondary: () => kpOpen(
              context,
              const TransferScreen(),
              title: 'Send money',
              step: 25,
            ),
          ),
        ),
        const SizedBox(height: 12),
        KpActionRow(
          children: [
            KpButton(
              label: 'Withdraw',
              style: KpButtonStyle.outline,
              onTap: () => kpOpen(
                context,
                TopUpScreen(usd: !xaf, withdraw: true),
                title: 'Withdraw',
                note: 'Payout to Mobile Money or bank',
              ),
            ),
            KpButton(
              label: 'To card',
              style: KpButtonStyle.soft,
              icon: Icons.credit_card_rounded,
              onTap: () {
                final token = AuthScope.maybeRead(context)?.sessionToken;
                if (token != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CardsPage(
                        repository: CardsRepository(baseUrl: kApiBase, token: token),
                      ),
                    ),
                  );
                  return;
                }
                kpOpen(context, const CardScreen(), title: 'Virtual card', step: 30);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        KpSectionHeader(
          title: 'Linked accounts',
          action: 'Manage',
          onAction: () => _showWalletSettings(context),
        ),
        const SizedBox(height: 8),
        const LinkedPhones(),
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
        const SizedBox(height: 2),
        const LiveActivityList(limit: 3),
        const SizedBox(height: 8),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Wallet balances are held with our licensed partner and protected by two-factor authentication.',
          ),
        ),
      ],
    );
  }

  void _showWalletSettings(BuildContext context) {
    final signedIn = AuthScope.maybeRead(context)?.sessionToken != null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wallet settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              KpSettingsTile(
                title: 'Default currency',
                icon: Icons.currency_exchange_rounded,
                trailingText: 'FCFA',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              KpSettingsTile(
                title: 'Linked accounts',
                icon: Icons.account_balance_wallet_outlined,
                trailingText: signedIn ? 'On this page' : '3 linked',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              KpSettingsTile(
                title: 'Statements',
                icon: Icons.description_outlined,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (!signedIn) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Statements are not available yet.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: KpColors.primary,
                    ),
                  );
                },
              ),
              KpSettingsTile(
                title: 'Close wallet',
                icon: Icons.link_off_rounded,
                danger: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (!signedIn) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Closing a wallet is not available.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: KpColors.primary,
                    ),
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
