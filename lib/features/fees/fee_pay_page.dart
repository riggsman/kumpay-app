import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/money/money_repository.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Pays a published school fee from the wallet.
class FeePayPage extends StatefulWidget {
  const FeePayPage({super.key, required this.repository, required this.institution});

  final MoneyRepository repository;
  final FeeInstitution institution;

  @override
  State<FeePayPage> createState() => _FeePayPageState();
}

class _FeePayPageState extends State<FeePayPage> {
  final _reference = TextEditingController();
  final _name = TextEditingController();
  List<FeeOption> _fees = const [];
  int _selected = 0;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _receipt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reference.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fees = await widget.repository.fees(widget.institution.code);
      if (!mounted) return;
      setState(() {
        _fees = fees;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : "Couldn't load fees.";
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_fees.isEmpty) return;
    final fee = _fees[_selected];
    if (_reference.text.trim().length < 2 || _name.text.trim().length < 2) {
      setState(() => _error = 'Enter the student reference and name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await widget.repository.payFee(
        institutionCode: widget.institution.code,
        periodId: fee.periodId,
        categoryCode: fee.categoryCode,
        studentReference: _reference.text.trim(),
        studentName: _name.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException ? error.message : "Couldn't complete that payment.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    return KpPage(
      header: KpSimpleHeader(
        title: widget.institution.name,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
        if (receipt != null) ...[
          const SizedBox(height: 16),
          const KpTip(tone: KpTipTone.success, child: Text('Payment recorded. Keep the receipt number.')),
          const SizedBox(height: 12),
          KpDetailCard(
            rows: [
              KpDetailRow('Receipt', receipt['receiptNumber']?.toString() ?? ''),
              KpDetailRow('Status', receipt['status']?.toString() ?? ''),
              KpDetailRow('School', widget.institution.name),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          if (_fees.isEmpty && !_loading) const Text('This school has no published fees.'),
          for (var i = 0; i < _fees.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(KpRadius.md),
                    border: Border.all(color: i == _selected ? KpColors.primary : KpColors.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(_fees[i].label, style: const TextStyle(fontWeight: FontWeight.w800))),
                      Text(_fees[i].amount.label),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          KpTextField(label: 'Student reference', hint: 'STU-1042', controller: _reference),
          const SizedBox(height: 12),
          KpTextField(label: 'Student name', hint: 'Aïcha Ngono', controller: _name),
          const SizedBox(height: 16),
          KpButton(label: _busy ? 'Paying…' : 'Pay from wallet', onTap: _busy || _fees.isEmpty ? null : _pay),
        ],
      ],
    );
  }
}
