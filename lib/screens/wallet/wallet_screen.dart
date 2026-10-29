import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/cards/cards_repository.dart';
import '../../data/demo.dart';
import '../../features/cards/cards_page.dart';
import '../../features/feature_flags/app_feature.dart';
import '../../features/money/live_money.dart';
import '../../features/wallet/wallet_settings.dart';
import '../../state/auth_scope.dart';
import '../../state/feature_flags_scope.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../cards/card_screen.dart';
import 'activity_screen.dart';
import 'devices_page.dart';
import 'linked_accounts_page.dart';
import 'statements_page.dart';
import 'top_up_screen.dart';
import 'transfer_screen.dart';
import 'wallet_settings_sheet.dart';

/// 24 — Wallet overview.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _tab = 0;
  var _tabTouched = false;
  var _settingsLoaded = false;
  WalletSettings _settings = WalletSettings.fallback;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = moneyRepo(context);
    if (repo == null) return;
    final cached = await repo.cachedSettings();
    if (mounted && cached != null) _applySettings(cached);
    final fresh = await repo.walletSettings();
    if (mounted) _applySettings(fresh);
  }

  void _applySettings(WalletSettings settings) {
    setState(() {
      _settings = settings;
      _settingsLoaded = true;
      if (!_tabTouched) {
        _tab = settings.defaultCurrency == 'USD' ? 1 : 0;
      }
    });
  }

  bool get _showXaf => _settings.offers('XAF');
  bool get _showUsd => _settings.offers('USD');

  int get _visibleTab {
    if (_showUsd && !_showXaf) return 1;
    if (!_showUsd) return 0;
    return _tab;
  }

  Future<void> _openAccounts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LinkedAccountsPage(repository: moneyRepo(context)),
      ),
    );
    if (mounted) await _loadSettings();
  }

  Future<void> _openStatements() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatementsPage(repository: moneyRepo(context)),
      ),
    );
  }

  Future<void> _openDevices() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DevicesPage(repository: moneyRepo(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xaf = _visibleTab == 0;
    final deposit = FeatureFlagsScope.enabled(context, AppFeature.deposit);
    final send = FeatureFlagsScope.enabled(context, AppFeature.send);
    final withdrawal = FeatureFlagsScope.enabled(
      context,
      AppFeature.withdrawal,
    );

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
        if (_showXaf && _showUsd) ...[
          KpSegmentedTabs(
            tabs: const ['FCFA wallet', 'USD wallet'],
            index: _visibleTab,
            onChanged: (i) => setState(() {
              _tabTouched = true;
              _tab = i;
            }),
          ),
          const SizedBox(height: 12),
        ],
        WalletAmount(
          key: ValueKey(_visibleTab),
          usd: !xaf,
          fallback: xaf ? formatXaf(demoUser.xaf) : '\$120.50',
          builder: (context, amount) => KpBalanceCard(
            amount: amount,
            label: xaf ? 'Available balance' : 'USD balance',
            account: xaf ? 'XAF wallet' : 'USD wallet',
            wallet: xaf ? 'KumPay Wallet' : 'Card funding account',
            primaryAction: 'Add money',
            secondaryAction: 'Send',
            showPrimary: deposit,
            showSecondary: send,
            onPrimary: deposit
                ? () => kpOpen(
                      context,
                      TopUpScreen(usd: !xaf),
                      title: 'Add money',
                      step: 0,
                    )
                : null,
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
        const SizedBox(height: 12),
        KpActionRow(
          children: [
            if (withdrawal)
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
          ],
        ),
        const SizedBox(height: 18),
        KpSectionHeader(
          title: 'Linked accounts',
          action: 'Manage',
          onAction: _openAccounts,
        ),
        const SizedBox(height: 8),
        LinkedAccountsCard(
          signedIn: AuthScope.maybeRead(context)?.sessionToken != null,
          loaded: _settingsLoaded,
          accounts: _settings.accounts,
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
    final repo = moneyRepo(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return WalletSettingsSheet(
          repository: repo,
          initial: repo == null ? null : (_settingsLoaded ? _settings : null),
          onAccounts: () {
            Navigator.of(sheetContext).pop();
            _openAccounts();
          },
          onStatements: () {
            Navigator.of(sheetContext).pop();
            _openStatements();
          },
          onDevices: () {
            Navigator.of(sheetContext).pop();
            _openDevices();
          },
          onWalletClosed: (result) async {
            Navigator.of(sheetContext).pop();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: KpColors.primary,
              ),
            );
            if (result.closed || result.signedOut) {
              await AuthScope.maybeRead(context)?.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        );
      },
    );
  }
}
