import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../data/money/money_repository.dart';
import '../../features/fees/fee_pay_page.dart';
import '../../features/money/live_money.dart';
import '../../state/auth_scope.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../home/home_screen.dart';

/// 27 — Bills hub.
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthScope.maybeRead(context)?.sessionToken != null;
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.pay),
      header: KpSimpleHeader(
        title: 'Pay bills',
        onBack: () => Navigator.of(context).maybePop(),
        trailing: KpIconButton(
          icon: Icons.search_rounded,
          size: 36,
          onTap: () => _showSearch(context),
        ),
      ),
      children: [
        Text(
          'What would you like to pay?',
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        if (signedIn)
          const _LiveBillers()
        else
          for (final bill in demoBills) ...[
            KpBillerChip(
              bill: bill,
              onTap: () => kpOpen(
                context,
                BillPayScreen(bill: bill),
                title: 'Pay ${bill.name}',
                step: 28,
              ),
            ),
            const SizedBox(height: 8),
          ],
        if (signedIn) ...[
          const SizedBox(height: 14),
          const KpTip(
            tone: KpTipTone.gold,
            child: Text('School fees are paid from your KumPay wallet.'),
          ),
        ],
        if (!signedIn) ...[
        const SizedBox(height: 10),
        const KpSectionHeader(title: 'Categories'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: KpServiceTile(
                label: 'Airtime',
                icon: Icons.smartphone_rounded,
                onTap: () => _soon(context, 'Airtime top-up'),
              ),
            ),
            Expanded(
              child: KpServiceTile(
                label: 'Internet',
                icon: Icons.wifi_rounded,
                tone: KpServiceTone.info,
                onTap: () => _soon(context, 'Internet bundles'),
              ),
            ),
            Expanded(
              child: KpServiceTile(
                label: 'School fees',
                icon: Icons.school_outlined,
                tone: KpServiceTone.gold,
                onTap: () => _soon(context, 'School fees'),
              ),
            ),
            Expanded(
              child: KpServiceTile(
                label: 'Taxes',
                icon: Icons.account_balance_outlined,
                tone: KpServiceTone.neutral,
                onTap: () => _soon(context, 'Tax payments'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            border: Border.all(color: KpColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Autopay',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                  ),
                  const Spacer(),
                  const KpPill(label: '2 active', tone: KpPillTone.green),
                ],
              ),
              const SizedBox(height: 10),
              _AutopayRow(
                name: 'Canal+ Premium',
                detail: 'Every 5th · 18 000 FCFA',
                icon: Icons.live_tv_rounded,
                onTap: () => kpOpen(
                  context,
                  BillPayScreen(bill: demoBills[2]),
                  title: 'Canal+',
                  step: 28,
                ),
              ),
              const SizedBox(height: 6),
              _AutopayRow(
                name: 'ENEO prepaid',
                detail: 'When below 5 000 FCFA',
                icon: Icons.bolt_rounded,
                onTap: () => kpOpen(
                  context,
                  BillPayScreen(bill: demoBills[0]),
                  title: 'ENEO',
                  step: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const KpTip(
          tone: KpTipTone.gold,
          child: Text(
            'Zero KumPay fees on ENEO prepaid payments until Sunday. Provider charges may still apply.',
          ),
        ),
        ],
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showSearch<void>(
      context: context,
      delegate: _BillerSearchDelegate(context),
    );
  }

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label is coming soon in this prototype.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KpColors.primary,
      ),
    );
  }
}

/// 28 — Pay a specific bill.
class BillPayScreen extends StatefulWidget {
  const BillPayScreen({super.key, required this.bill});

  final KpBill bill;

  @override
  State<BillPayScreen> createState() => _BillPayScreenState();
}

class _BillPayScreenState extends State<BillPayScreen> {
  final _reference = TextEditingController();
  final _amount = TextEditingController(text: '12 500');

  @override
  void initState() {
    super.initState();
    _reference.text = widget.bill.reference;
  }

  @override
  void dispose() {
    _reference.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount =
        int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.pay),
      header: KpSimpleHeader(
        title: widget.bill.name,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label:
            'Pay ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} FCFA',
        onTap: () => kpOpen(
          context,
          BillSuccessScreen(bill: widget.bill, amount: amount),
          title: 'Payment successful',
          step: 28,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KpColors.goldSoft,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            border: Border.all(color: KpColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: KpColors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child:
                    Icon(widget.bill.icon, size: 22, color: KpColors.goldDeep),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bill.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.bill.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink2,
                            fontSize: 9.5,
                          ),
                    ),
                  ],
                ),
              ),
              const KpPill(label: 'Verified', tone: KpPillTone.green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KpTextField(
          label: widget.bill.referenceLabel,
          controller: _reference,
          prefixIcon: Icons.confirmation_number_outlined,
        ),
        const SizedBox(height: 14),
        const KpFieldLabel('Amount'),
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 25,
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
              const Text(
                'FCFA',
                style: TextStyle(
                  color: KpColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          children: [
            for (final value in [5000, 12500, 25000, 50000])
              InkWell(
                onTap: () => setState(() => _amount.text = value.toString()),
                borderRadius: BorderRadius.circular(KpRadius.pill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: KpColors.surface,
                    borderRadius: BorderRadius.circular(KpRadius.pill),
                    border: Border.all(color: KpColors.line),
                  ),
                  child: Text(
                    '${value ~/ 1000}k',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KpColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        KpDetailCard(
          rows: [
            KpDetailRow('Provider', widget.bill.name),
            KpDetailRow('Meter / contract', _reference.text),
            const KpDetailRow('Payment fee', 'Free'),
            KpDetailRow('Total', '$amount FCFA', total: true),
          ],
        ),
        const SizedBox(height: 10),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Your payment is confirmed by the provider within seconds. Keep the reference for your records.',
          ),
        ),
      ],
    );
  }
}

/// 28b — Bill payment success.
class BillSuccessScreen extends StatelessWidget {
  const BillSuccessScreen({
    super.key,
    required this.bill,
    required this.amount,
  });

  final KpBill bill;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );

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
                    title: 'Payment successful',
                    body: '$formatted FCFA paid to ${bill.name}.',
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
                            KpDetailRow('Biller', bill.name),
                            KpDetailRow(bill.referenceLabel, bill.reference),
                            KpDetailRow('Amount', '$formatted FCFA'),
                            const KpDetailRow('Fee', 'Free'),
                            const KpDetailRow('Reference', 'KP-ENEO-7742'),
                            const KpDetailRow('Date', '24 May 2026 · 09:41'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const KpTip(
                          tone: KpTipTone.success,
                          child: Text(
                            'Your meter has been topped up. A receipt was sent to your primary phone.',
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
                          'Pay another bill',
                          color: KpColors.muted,
                          onTap: () => kpOpen(
                            context,
                            const BillsScreen(),
                            title: 'Pay bills',
                            step: 27,
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
          kpAppNav(context, active: KpTab.pay),
          const KpHomeIndicator(),
        ],
      ),
    );
  }
}

class _AutopayRow extends StatelessWidget {
  const _AutopayRow({
    required this.name,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 17, color: KpColors.goldDeep),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                  ),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 17, color: KpColors.muted),
          ],
        ),
      ),
    );
  }
}

class _BillerSearchDelegate extends SearchDelegate<void> {
  _BillerSearchDelegate(this.host) {
    repo = moneyRepo(host);
    _schools = repo?.institutions();
  }

  final BuildContext host;
  late final MoneyRepository? repo;
  late final Future<List<FeeInstitution>>? _schools;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.close_rounded),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_rounded),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final schools = _schools;
    if (schools != null && repo != null) {
      return FutureBuilder<List<FeeInstitution>>(
        future: schools,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ColoredBox(
              color: KpColors.canvas,
              child: Center(child: Text('Loading schools…')),
            );
          }
          final items = (snapshot.data ?? const <FeeInstitution>[])
              .where((school) =>
                  school.name.toLowerCase().contains(query.toLowerCase()) ||
                  school.code.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Container(
            color: KpColors.canvas,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (snapshot.hasError)
                  const Text('Could not load schools.')
                else if (items.isEmpty)
                  Text('No schools match “$query”.')
                else
                  for (final school in items)
                    ListTile(
                      title: Text(school.name),
                      subtitle: Text(school.code),
                      onTap: () {
                        close(context, null);
                        Navigator.of(host).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FeePayPage(repository: repo!, institution: school),
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
    final matches = demoBills
        .where((b) =>
            b.name.toLowerCase().contains(query.toLowerCase()) ||
            b.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: KpColors.canvas,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (matches.isEmpty)
            Center(
              child: Text(
                'No billers match “$query”.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                    ),
              ),
            )
          else
            for (final bill in matches) ...[
              KpBillerChip(
                bill: bill,
                onTap: () {
                  close(context, null);
                  kpOpen(
                    context,
                    BillPayScreen(bill: bill),
                    title: 'Pay ${bill.name}',
                    step: 28,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _LiveBillers extends StatefulWidget {
  const _LiveBillers();

  @override
  State<_LiveBillers> createState() => _LiveBillersState();
}

class _LiveBillersState extends State<_LiveBillers> {
  List<FeeInstitution> _items = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final repo = moneyRepo(context);
    if (repo == null) return;
    repo.institutions().then((items) {
      if (mounted) setState(() => _items = items);
    }).catchError((Object _) {
      if (mounted) setState(() => _error = 'Could not load schools.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = moneyRepo(context);
    if (_error != null) return Text(_error!);
    if (_items.isEmpty) return const Text('Loading schools you can pay…');
    return Column(
      children: [
        for (final school in _items) ...[
          Material(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            child: InkWell(
              onTap: repo == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FeePayPage(repository: repo, institution: school),
                        ),
                      ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KpRadius.md),
                  border: Border.all(color: KpColors.line),
                ),
                child: Text(school.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
