import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/phone.dart';
import '../../data/money/money_repository.dart';
import '../../features/money/live_money.dart';
import '../../features/wallet/wallet_settings.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Adds and removes the funding accounts stored for this wallet.
class LinkedAccountsPage extends StatefulWidget {
  const LinkedAccountsPage({super.key, this.repository});

  final MoneyRepository? repository;

  @override
  State<LinkedAccountsPage> createState() => _LinkedAccountsPageState();
}

class _LinkedAccountsPageState extends State<LinkedAccountsPage> {
  static const _preview = [
    LinkedAccount(
      id: 'preview-mtn',
      label: 'MTN Mobile Money',
      kind: 'momo',
      detail: '+237 677 ••• 456',
    ),
    LinkedAccount(
      id: 'preview-orange',
      label: 'Orange Money',
      kind: 'momo',
      detail: '+237 699 ••• 118',
    ),
    LinkedAccount(
      id: 'preview-bank',
      label: 'Afriland First Bank',
      kind: 'bank',
      detail: '•••• 3391',
    ),
  ];

  List<LinkedAccount> _accounts = const [];
  var _loading = true;
  var _busy = false;
  String? _error;

  MoneyRepository? get _repo => widget.repository ?? moneyRepo(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.repository ?? moneyRepo(context);
    if (repo == null) {
      setState(() {
        _accounts = _preview;
        _loading = false;
      });
      return;
    }
    final cached = await repo.cachedSettings();
    if (mounted && cached != null) {
      setState(() {
        _accounts = cached.accounts;
        _loading = false;
      });
    }
    final settings = await repo.walletSettings();
    if (!mounted) return;
    setState(() {
      _accounts = settings.accounts;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final repo = _repo;
    final draft = await showModalBottomSheet<_AccountDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddAccountSheet(),
    );
    if (draft == null || !mounted) return;
    if (repo == null) {
      setState(() => _error = 'Sign in to add an account.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.addAccount(
        label: draft.label,
        kind: draft.kind,
        detail: draft.detail,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't add that account.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(LinkedAccount account) async {
    final repo = _repo;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Remove account'),
        content: Text('Remove ${account.label} from this wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (repo == null) {
      setState(() => _error = 'Sign in to remove an account.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.removeAccount(account.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't remove that account.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      header: KpSimpleHeader(
        title: 'Linked accounts',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: _busy ? 'Saving…' : 'Add account',
        icon: Icons.add_rounded,
        onTap: _busy ? null : _add,
      ),
      children: [
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Accounts are stored on your KumPay profile. Add a mobile-money number or a bank account, or remove one you no longer use.',
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_accounts.isEmpty)
          const KpDetailCard(
            rows: [KpDetailRow('Linked accounts', 'None yet')],
          )
        else
          for (final account in _accounts) ...[
            _AccountRow(
              account: account,
              onRemove: _busy ? null : () => _remove(account),
            ),
            const SizedBox(height: 8),
          ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
      ],
    );
  }
}

class LinkedAccountsCard extends StatelessWidget {
  const LinkedAccountsCard({
    super.key,
    required this.signedIn,
    required this.loaded,
    required this.accounts,
  });

  final bool signedIn;
  final bool loaded;
  final List<LinkedAccount> accounts;

  @override
  Widget build(BuildContext context) {
    if (!signedIn) {
      return const KpDetailCard(
        rows: [
          KpDetailRow('MTN Mobile Money', '+237 677 ••• 456'),
          KpDetailRow('Orange Money', '+237 699 ••• 118'),
          KpDetailRow('Afriland First Bank', '•••• 3391'),
        ],
      );
    }
    if (!loaded) {
      return const KpDetailCard(
        rows: [KpDetailRow('Linked accounts', 'Loading…')],
      );
    }
    if (accounts.isEmpty) {
      return const KpDetailCard(
        rows: [KpDetailRow('Linked accounts', 'None yet')],
      );
    }
    return KpDetailCard(
      rows: [
        for (final account in accounts)
          KpDetailRow(account.label, account.detail),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.onRemove});

  final LinkedAccount account;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        children: [
          Icon(
            account.kind == 'bank'
                ? Icons.account_balance_outlined
                : Icons.phone_iphone_rounded,
            color: KpColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${account.kindLabel} · ${account.detail}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.muted,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('remove-account-${account.id}'),
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: KpColors.danger),
          ),
        ],
      ),
    );
  }
}

class _AccountDraft {
  const _AccountDraft({
    required this.label,
    required this.kind,
    required this.detail,
  });

  final String label;
  final String kind;
  final String detail;
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _label = TextEditingController();
  final _detail = TextEditingController();
  var _bank = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _detail.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    final raw = _detail.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Enter a name for this account.');
      return;
    }
    if (_bank) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 6) {
        setState(() => _error = 'Enter the bank account number.');
        return;
      }
      Navigator.of(context).pop(
        _AccountDraft(label: label, kind: 'bank', detail: digits),
      );
      return;
    }
    final phone = Phone.normalize(raw);
    if (phone == null) {
      setState(() => _error = 'Enter a Cameroon mobile number.');
      return;
    }
    Navigator.of(context).pop(
      _AccountDraft(label: label, kind: 'momo', detail: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 4, 22, 22 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Mobile money'),
                selected: !_bank,
                onSelected: (_) => setState(() => _bank = false),
              ),
              ChoiceChip(
                label: const Text('Bank'),
                selected: _bank,
                onSelected: (_) => setState(() => _bank = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          KpTextField(
            label: 'Name',
            hint: _bank ? 'Afriland First Bank' : 'MTN Mobile Money',
            controller: _label,
          ),
          const SizedBox(height: 12),
          KpTextField(
            label: _bank ? 'Account number' : 'Phone number',
            hint: _bank ? '10005 3391' : '677 12 34 56',
            controller: _detail,
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            KpInlineError(_error!),
          ],
          const SizedBox(height: 16),
          KpButton(label: 'Save account', onTap: _save),
        ],
      ),
    );
  }
}
