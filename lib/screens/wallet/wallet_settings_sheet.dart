import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/money/money_repository.dart';
import '../../features/wallet/wallet_settings.dart';
import '../../widgets/kp_controls.dart';

/// Wallet settings. The default currency is shown from the database cache and
/// cannot be edited. Close wallet is omitted until the database enables it.
class WalletSettingsSheet extends StatefulWidget {
  const WalletSettingsSheet({
    super.key,
    this.repository,
    this.initial,
    this.onAccounts,
    this.onStatements,
    this.onDevices,
    this.onWalletClosed,
  });

  final MoneyRepository? repository;
  final WalletSettings? initial;
  final VoidCallback? onAccounts;
  final VoidCallback? onStatements;
  final VoidCallback? onDevices;
  final ValueChanged<WalletClosure>? onWalletClosed;

  @override
  State<WalletSettingsSheet> createState() => _WalletSettingsSheetState();
}

class _WalletSettingsSheetState extends State<WalletSettingsSheet> {
  late WalletSettings _settings = widget.initial ?? WalletSettings.fallback;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.repository;
    if (repo == null) return;
    final cached = widget.initial ?? await repo.cachedSettings();
    if (mounted && cached != null) setState(() => _settings = cached);
    final fresh = await repo.walletSettings();
    if (mounted) setState(() => _settings = fresh);
  }

  Future<void> _explainCurrency() async {
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Default currency'),
        content: Text(
          'Your default currency is ${_settings.defaultCurrencyLabel}. KumPay sets this on your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeWallet() async {
    final repo = widget.repository;
    if (repo == null || !_settings.closeWalletEnabled) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Close wallet'),
        content: const Text(
          'Closing your wallet is permanent. Balances must be withdrawn first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep wallet'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Close wallet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await repo.closeWallet();
      if (!mounted) return;
      widget.onWalletClosed?.call(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException
            ? error.message
            : "Couldn't close the wallet.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountCount = _settings.accounts.length;
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
            trailingText: _settings.defaultCurrencyLabel,
            locked: true,
            onTap: _explainCurrency,
          ),
          KpSettingsTile(
            title: 'Linked accounts',
            icon: Icons.account_balance_wallet_outlined,
            trailingText: widget.repository == null && widget.initial == null
                ? '3 linked'
                : (accountCount == 0 ? 'None' : '$accountCount linked'),
            onTap: widget.onAccounts,
          ),
          KpSettingsTile(
            title: 'Statements',
            icon: Icons.description_outlined,
            onTap: widget.onStatements,
          ),
          KpSettingsTile(
            title: 'Linked devices',
            icon: Icons.devices_outlined,
            onTap: widget.onDevices,
          ),
          if (_settings.closeWalletEnabled)
            KpSettingsTile(
              title: 'Close wallet',
              icon: Icons.link_off_rounded,
              danger: true,
              onTap: _busy ? null : _closeWallet,
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            KpInlineError(_error!),
          ],
        ],
      ),
    );
  }
}
