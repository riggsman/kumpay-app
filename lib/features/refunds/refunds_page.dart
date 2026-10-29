import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/refunds/refunds_repository.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// A client refund request. Finance validates it, then a second person approves it.
class RefundsPage extends StatefulWidget {
  const RefundsPage({super.key, required this.repository});

  final RefundsRepository repository;

  @override
  State<RefundsPage> createState() => _RefundsPageState();
}

class _RefundsPageState extends State<RefundsPage> {
  final _reference = TextEditingController();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  String _currency = 'XAF';
  List<RefundView> _items = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _reference.dispose();
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final items = await widget.repository.list();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (_reference.text.trim().length < 3) {
      setState(() => _error = 'Enter the payment reference.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (_reason.text.trim().length < 3) {
      setState(() => _error = 'Say why you are asking for a refund.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.create(
        transactionId: _reference.text.trim(),
        amount: amount,
        currency: _currency,
        reason: _reason.text.trim(),
      );
      _reference.clear();
      _amount.clear();
      _reason.clear();
      await _reload();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpSimpleHeader(
        title: 'Refunds',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpScreenTitle(
          'Request a refund',
          'Finance reviews it first. A second person then approves or rejects it. Money moves only after that second approval.',
        ),
        const SizedBox(height: 14),
        KpTextField(label: 'Payment reference', controller: _reference, hint: 'txn_123'),
        const SizedBox(height: 12),
        const KpFieldLabel('Currency'),
        Wrap(
          spacing: 8,
          children: [
            for (final currency in const ['XAF', 'USD'])
              ChoiceChip(
                label: Text(currency),
                selected: _currency == currency,
                onSelected: (_) => setState(() => _currency = currency),
              ),
          ],
        ),
        const SizedBox(height: 12),
        KpTextField(
          label: 'Amount',
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        KpTextField(label: 'Reason', controller: _reason, maxLines: 3, maxLength: 2000),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 16),
        KpButton(label: 'Submit request', busy: _busy, onTap: _busy ? null : _submit),
        const SizedBox(height: 18),
        const KpSectionHeader(title: 'Your requests'),
        if (_loading)
          const LinearProgressIndicator(minHeight: 2)
        else if (_items.isEmpty)
          const Text('You have not requested a refund.', style: TextStyle(color: KpColors.muted, fontSize: 12))
        else
          for (final item in _items) ...[
            _RefundTile(item: item),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _RefundTile extends StatelessWidget {
  const _RefundTile({required this.item});

  final RefundView item;

  @override
  Widget build(BuildContext context) {
    final money = item.currency == 'USD' ? '\$${item.amount.toStringAsFixed(2)}' : '${item.amount.toStringAsFixed(0)} XAF';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(money, style: const TextStyle(fontWeight: FontWeight.w800))),
              KpPill(label: _label(item.status), tone: _tone(item.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.reason, style: const TextStyle(color: KpColors.muted, fontSize: 11)),
          if (item.resolution != null && item.resolution!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.resolution!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

String _label(String status) {
  return switch (status) {
    'validated' => 'With approver',
    'approved' => 'Refunded',
    'rejected' => 'Rejected',
    _ => 'With finance',
  };
}

KpPillTone _tone(String status) {
  return switch (status) {
    'approved' => KpPillTone.green,
    'rejected' => KpPillTone.red,
    'validated' => KpPillTone.gold,
    _ => KpPillTone.neutral,
  };
}

String _message(Object error) {
  if (error is ApiException) return error.message;
  return "Couldn't reach KumPay. Check your connection and try again.";
}
