import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../features/money/live_money.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';

/// Add money / withdraw — deposit method and amount.
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key, this.usd = false, this.withdraw = false});

  final bool usd;
  final bool withdraw;

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amount = TextEditingController(text: '25 000');
  int _method = 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usd = widget.usd;
    final withdraw = widget.withdraw;
    final methods = withdraw
        ? const [
            (
              'MTN Mobile Money',
              '••• 456 · Instant',
              Icons.phone_android_rounded
            ),
            (
              'Afriland First Bank',
              '•••• 3391 · 1 business day',
              Icons.account_balance_rounded
            ),
          ]
        : usd
            ? const [
                (
                  'Debit card',
                  'Visa / Mastercard · Instant',
                  Icons.credit_card_rounded
                ),
                (
                  'USD bank transfer',
                  '1–2 business days',
                  Icons.account_balance_rounded
                ),
              ]
            : const [
                (
                  'MTN Mobile Money',
                  '••• 456 · Instant',
                  Icons.phone_android_rounded
                ),
                (
                  'Orange Money',
                  '••• 118 · Instant',
                  Icons.phone_android_rounded
                ),
                (
                  'Afriland First Bank',
                  '•••• 3391 · Instant',
                  Icons.account_balance_rounded
                ),
              ];

    final amount =
        int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final fee = withdraw ? 0 : (usd ? 50 : 100);
    final total = amount + fee;

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      header: KpSimpleHeader(
        title: withdraw ? 'Withdraw money' : 'Add money',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: withdraw ? 'Withdraw' : 'Add money',
        onTap: () => _confirm(context, amount),
      ),
      children: [
        Text(
          withdraw
              ? 'How much do you want to withdraw?'
              : 'How much do you want to add?',
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            border: Border.all(color: KpColors.primary, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: KpColors.primary.withValues(alpha: 0.08),
                blurRadius: 0,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                usd ? '\$' : 'FCFA',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: KpColors.muted,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final value
                in (usd ? [25, 50, 100, 250] : [10000, 25000, 50000, 100000]))
              InkWell(
                onTap: () => setState(() {
                  _amount.text = usd
                      ? value.toString()
                      : value.toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+$)'),
                            (m) => '${m[1]} ',
                          );
                }),
                borderRadius: BorderRadius.circular(KpRadius.pill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: KpColors.surface,
                    borderRadius: BorderRadius.circular(KpRadius.pill),
                    border: Border.all(color: KpColors.line),
                  ),
                  child: Text(
                    usd ? '\$$value' : '${value ~/ 1000}k',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KpColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        KpSectionHeader(title: withdraw ? 'Withdraw to' : 'Payment method'),
        const SizedBox(height: 8),
        for (var i = 0; i < methods.length; i++) ...[
          InkWell(
            onTap: () => setState(() => _method = i),
            borderRadius: BorderRadius.circular(KpRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: _method == i ? KpColors.softGreen : KpColors.surface,
                borderRadius: BorderRadius.circular(KpRadius.md),
                border: Border.all(
                  color: _method == i ? KpColors.primary : KpColors.line,
                  width: _method == i ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: KpColors.surface,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child:
                        Icon(methods[i].$3, size: 18, color: KpColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          methods[i].$1,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KpColors.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          methods[i].$2,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KpColors.muted,
                                    fontSize: 9,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _method == i
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 19,
                    color: _method == i ? KpColors.primary : KpColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (i < methods.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 18),
        KpDetailCard(
          rows: [
            KpDetailRow('Amount', usd ? '\$$amount' : '$amount FCFA'),
            KpDetailRow(
              withdraw ? 'Withdrawal fee' : 'Processing fee',
              fee == 0 ? 'Free' : (usd ? '\$$fee' : '$fee FCFA'),
            ),
            KpDetailRow(
              withdraw ? 'You receive' : 'Total to pay',
              usd
                  ? '\$${withdraw ? amount - fee : total}'
                  : '${withdraw ? amount - fee : total} FCFA',
              total: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Deposits are credited instantly from Mobile Money. Bank transfers may take up to 2 business days.',
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, int amount) async {
    final repo = moneyRepo(context);
    if (repo == null) {
      _showSuccess(context, amount);
      return;
    }
    try {
      await repo.cash(amount: amount.toDouble(), currency: widget.usd ? 'USD' : 'XAF', withdraw: widget.withdraw);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException
          ? error.message
          : "Couldn't reach KumPay. Check your connection and try again.";
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: KpColors.surface,
        showDragHandle: true,
        builder: (sheet) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.withdraw ? 'Withdrawal not open' : 'Deposit not open',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(message),
              const SizedBox(height: 14),
              KpButton(label: 'Close', onTap: () => Navigator.of(sheet).pop()),
            ],
          ),
        ),
      );
    }
  }

  void _showSuccess(BuildContext context, int total) {
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
                  child: KpStateIcon(type: KpStateIconType.success, size: 64)),
              const SizedBox(height: 14),
              Text(
                widget.withdraw ? 'Withdrawal started' : 'Money added',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.withdraw
                    ? '${widget.usd ? '\$' : ''}$total ${widget.usd ? '' : 'FCFA'} is on its way.'
                    : '${widget.usd ? '\$' : ''}$total ${widget.usd ? '' : 'FCFA'} will appear in your wallet shortly.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 10.5,
                    ),
              ),
              const SizedBox(height: 18),
              KpButton(
                label: 'Done',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
