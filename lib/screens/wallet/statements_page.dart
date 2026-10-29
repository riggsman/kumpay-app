import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/money/money_repository.dart';
import '../../features/money/live_money.dart';
import '../../features/wallet/wallet_settings.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Lists wallet statements and lets the person request or remove one.
class StatementsPage extends StatefulWidget {
  const StatementsPage({super.key, this.repository});

  final MoneyRepository? repository;

  @override
  State<StatementsPage> createState() => _StatementsPageState();
}

class _StatementsPageState extends State<StatementsPage> {
  static const _preview = [
    WalletStatement(
      id: 'preview-may',
      period: '2026-05',
      currency: 'XAF',
      status: 'ready',
      reference: 'KP-STMT-2026-05',
    ),
  ];

  List<WalletStatement> _items = const [];
  var _currencies = const ['XAF', 'USD'];
  var _defaultCurrency = 'XAF';
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
        _items = _preview;
        _loading = false;
      });
      return;
    }
    try {
      final settings = await repo.walletSettings();
      final items = await repo.statements();
      if (!mounted) return;
      setState(() {
        _currencies = settings.currencies;
        _defaultCurrency = settings.defaultCurrency;
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            error is ApiException ? error.message : "Couldn't load statements.";
      });
    }
  }

  Future<void> _request() async {
    final repo = _repo;
    final draft = await showModalBottomSheet<_StatementDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RequestStatementSheet(
        currencies: _currencies,
        defaultCurrency: _defaultCurrency,
      ),
    );
    if (draft == null || !mounted) return;
    if (repo == null) {
      setState(() => _error = 'Sign in to request a statement.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.requestStatement(
          period: draft.period, currency: draft.currency);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't request that statement.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(WalletStatement statement) async {
    final repo = _repo;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Remove statement'),
        content: Text('Remove the ${statement.periodLabel} statement?'),
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
      setState(() => _error = 'Sign in to remove a statement.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.removeStatement(statement.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't remove that statement.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(WalletStatement statement) {
    final lines = <String>[
      statement.periodLabel,
      currencyLabel(statement.currency),
      if (statement.reference.isNotEmpty) statement.reference,
      if (statement.downloadUrl.isNotEmpty) statement.downloadUrl,
      if (!statement.isReady) 'This statement is still being prepared.',
    ];
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Statement'),
        content: Text(lines.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      header: KpSimpleHeader(
        title: 'Statements',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: _busy ? 'Saving…' : 'Request statement',
        icon: Icons.description_outlined,
        onTap: _busy ? null : _request,
      ),
      children: [
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Request a monthly statement for a wallet. Ready files stay in this list until you remove them.',
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_items.isEmpty)
          const KpDetailCard(
            rows: [KpDetailRow('Statements', 'None yet')],
          )
        else
          for (final statement in _items) ...[
            _StatementRow(
              statement: statement,
              onOpen: () => _open(statement),
              onRemove: _busy ? null : () => _remove(statement),
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

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.statement,
    required this.onOpen,
    required this.onRemove,
  });

  final WalletStatement statement;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final status = switch (statement.status) {
      'ready' => 'Ready',
      'failed' => 'Failed',
      _ => 'Preparing',
    };
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(KpRadius.md),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: KpColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statement.periodLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${currencyLabel(statement.currency)} · $status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('remove-statement-${statement.id}'),
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: KpColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementDraft {
  const _StatementDraft({required this.period, required this.currency});

  final String period;
  final String currency;
}

class _RequestStatementSheet extends StatefulWidget {
  const _RequestStatementSheet({
    required this.currencies,
    required this.defaultCurrency,
  });

  final List<String> currencies;
  final String defaultCurrency;

  @override
  State<_RequestStatementSheet> createState() => _RequestStatementSheetState();
}

class _RequestStatementSheetState extends State<_RequestStatementSheet> {
  final _period = TextEditingController();
  late String _currency = canonicalCurrency(widget.defaultCurrency);
  String? _error;

  @override
  void dispose() {
    _period.dispose();
    super.dispose();
  }

  void _save() {
    final period = _period.text.trim();
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(period)) {
      setState(() => _error = 'Enter a month as YYYY-MM.');
      return;
    }
    Navigator.of(context).pop(
      _StatementDraft(period: period, currency: _currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final currencies = widget.currencies.isEmpty
        ? const ['XAF']
        : widget.currencies.map(canonicalCurrency).toSet().toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 4, 22, 22 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Request statement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          KpTextField(
            label: 'Month',
            hint: '2026-05',
            controller: _period,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const KpFieldLabel('Wallet'),
          Wrap(
            spacing: 8,
            children: [
              for (final code in currencies)
                ChoiceChip(
                  label: Text(currencyLabel(code)),
                  selected: _currency == code,
                  onSelected: (_) => setState(() => _currency = code),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            KpInlineError(_error!),
          ],
          const SizedBox(height: 16),
          KpButton(label: 'Request', onTap: _save),
        ],
      ),
    );
  }
}
