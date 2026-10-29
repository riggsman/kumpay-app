import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../features/feature_flags/app_feature.dart';
import '../../features/money/live_money.dart';
import '../../features/transactions/transaction_authorizer.dart';
import '../../features/transactions/transaction_gate.dart';
import '../../preview/preview_page.dart';
import '../../state/auth_scope.dart';
import '../../state/feature_flags_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../home/home_screen.dart';

/// 25 — Send money.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _phone = TextEditingController();
  final _amount = TextEditingController(text: '15 000');
  final _note = TextEditingController();
  int _tab = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final repo = moneyRepo(context);
    if (_tab != 0) {
      if (repo != null) {
        setState(
          () => _error = 'Bank and Mobile Money payouts are not open yet.',
        );
        return;
      }
      if (!mounted) return;
      kpOpen(
        context,
        const TransferSuccessScreen(),
        title: 'Transfer complete',
        step: 26,
      );
      return;
    }
    final amount = double.tryParse(
      _amount.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (_phone.text.trim().length < 6 || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a KumPay number and an amount.');
      return;
    }
    final enabled = FeatureFlagsScope.enabled(context, AppFeature.send);
    final kyc = AuthScope.maybeRead(context)?.user?.kyc;
    if (repo == null) {
      if (!mounted) return;
      kpOpen(
        context,
        const TransferSuccessScreen(),
        title: 'Transfer complete',
        step: 26,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await runMoneyMovement(
        context,
        kind: TransactionKind.send,
        amount: amount,
        currency: 'XAF',
        action: ({mfaCode, challengeId}) => repo.transfer(
          phone: _phone.text.trim(),
          amount: amount,
          currency: 'XAF',
          note: _note.text.trim(),
          kyc: kyc,
          featureEnabled: enabled,
          mfaCode: mfaCode,
          challengeId: challengeId,
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (result == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransferSuccessScreen(
            recipient: result.recipientName,
            phone: result.phone,
            amount: result.amount.label,
            reference: result.reference,
            date: result.createdAt ?? '',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException
            ? error.message
            : "Couldn't send that transfer.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlagsScope.enabled(context, AppFeature.send)) {
      return KpPage(
        bottomNav: kpAppNav(context, active: KpTab.send),
        header: KpSimpleHeader(
          title: 'Send money',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        children: const [
          KpTip(
            tone: KpTipTone.info,
            child: Text('Sending money is turned off right now.'),
          ),
        ],
      );
    }
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.send),
      header: KpSimpleHeader(
        title: 'Send money',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: _busy ? 'Sending…' : 'Continue',
        icon: Icons.arrow_forward_rounded,
        onTap: _busy ? null : _send,
      ),
      children: [
        KpSegmentedTabs(
          tabs: const ['To KumPay', 'To bank / MoMo'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        KpTextField(
          label: _tab == 0 ? 'Recipient phone or name' : 'Account number',
          hint: _tab == 0 ? '677 98 76 54' : 'Enter account or MoMo number',
          controller: _phone,
          prefixIcon: Icons.search_rounded,
          keyboardType: _tab == 0 ? TextInputType.phone : TextInputType.number,
        ),
        const SizedBox(height: 14),
        Text(
          'Recent',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: KpColors.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 68,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: const [
              _RecentRecipient(
                initials: 'CF',
                name: 'Clarisse',
                tone: KpColors.softGreen,
              ),
              SizedBox(width: 8),
              _RecentRecipient(
                initials: 'PM',
                name: 'Paul M.',
                tone: KpColors.goldSoft,
              ),
              SizedBox(width: 8),
              _RecentRecipient(
                initials: 'AN',
                name: 'Ariane',
                tone: KpColors.infoSoft,
              ),
              SizedBox(width: 8),
              _RecentRecipient(
                initials: 'JD',
                name: 'Jean D.',
                tone: KpColors.soft,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Amount',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: KpColors.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontSize: 25, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Text(
                'FCFA',
                style: TextStyle(
                  color: KpColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 13,
              color: KpColors.muted,
            ),
            const SizedBox(width: 4),
            Text(
              'Balance: 248 500 FCFA',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: KpColors.muted, fontSize: 9),
            ),
            const Spacer(),
            KpTextLink(
              'Use max',
              onTap: () => setState(() => _amount.text = '248 500'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        KpTextField(
          label: 'Note',
          hint: 'What is this for?',
          controller: _note,
          optional: 'optional',
          maxLength: 60,
          prefixIcon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: 16),
        KpDetailCard(
          rows: [
            KpDetailRow('Transfer amount', '${_amount.text} FCFA'),
            const KpDetailRow('Transfer fee', 'Free'),
            KpDetailRow('Recipient gets', '${_amount.text} FCFA', total: true),
          ],
        ),
        const SizedBox(height: 12),
        const KpTip(
          tone: KpTipTone.success,
          child: Text(
            'KumPay transfers between wallets are instant and free. Check the recipient name before you send.',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
      ],
    );
  }
}

/// 26 — Transfer success.
class TransferSuccessScreen extends StatelessWidget {
  const TransferSuccessScreen({
    super.key,
    this.recipient = 'Clarisse Fouda',
    this.phone = '+237 677 ••• 654',
    this.amount = '15 000 FCFA',
    this.reference = 'KP-9F2A-8841',
    this.date = '24 May 2026 · 09:41',
  });

  final String recipient;
  final String phone;
  final String amount;
  final String reference;
  final String date;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KpColors.primary,
      child: Column(
        children: [
          const KpStatusBar(onDark: true),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  KpSuccessHero(
                    title: 'Money sent!',
                    body: '$amount is on its way to $recipient.',
                    compact: true,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    color: KpColors.canvas,
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KpDetailCard(
                          rows: [
                            KpDetailRow('Recipient', recipient),
                            KpDetailRow('Phone', phone),
                            KpDetailRow('Amount', amount),
                            const KpDetailRow('Fee', 'Free'),
                            KpDetailRow('Reference', reference),
                            KpDetailRow('Date', date),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const KpTip(
                          tone: KpTipTone.success,
                          child: Text(
                            'Clarisse has been notified by SMS and will see the money instantly.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        KpButton(
                          label: 'Back to home',
                          style: KpButtonStyle.success,
                          onTap: () => kpOpen(
                            context,
                            const HomeScreen(),
                            title: 'Home dashboard',
                            step: 23,
                          ),
                        ),
                        KpTextLink(
                          'Send another',
                          color: KpColors.muted,
                          onTap: () => kpOpen(
                            context,
                            const TransferScreen(),
                            title: 'Send money',
                            step: 25,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          kpAppNav(context, active: KpTab.send),
          const KpHomeIndicator(),
        ],
      ),
    );
  }
}

class _RecentRecipient extends StatelessWidget {
  const _RecentRecipient({
    required this.initials,
    required this.name,
    required this.tone,
  });

  final String initials;
  final String name;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            child: Text(
              initials,
              style: const TextStyle(
                color: KpColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: KpColors.ink2, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}
