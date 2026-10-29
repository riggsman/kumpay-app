import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/demo.dart';
import '../../data/money/money_repository.dart';
import '../../features/autopay/autopay_controller.dart';
import '../../features/autopay/autopay_plan.dart';
import '../../features/feature_flags/app_feature.dart';
import '../../features/fees/fee_pay_page.dart';
import '../../features/services/platform_service.dart';
import '../../features/services/service_pay_page.dart';
import '../../features/money/live_money.dart';
import '../../features/transactions/transaction_authorizer.dart';
import '../../features/transactions/transaction_gate.dart';
import '../../state/auth_scope.dart';
import '../../state/feature_flags_scope.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../profile/autopay_page.dart';

/// 27 — Bills hub.
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthScope.maybeRead(context)?.sessionToken != null;
    final billsOn = FeatureFlagsScope.enabled(context, AppFeature.bills);
    final schoolsOn = billFeatureEnabled(context, 'school_fees');
    final visibleBills =
        demoBills.where((bill) => _billOn(context, bill)).toList();
    final platformServices = billsOn
        ? (FeatureFlagsScope.maybeOf(context)?.snapshot.services ??
            const <PlatformService>[])
        : const <PlatformService>[];
    final payTiles = <Widget>[
      if (billsOn)
        for (final bill in visibleBills)
          KpServiceTile(
            label: bill.name,
            icon: bill.icon,
            tone: _billTone(bill.id),
            maxLines: 2,
            onTap: () => kpOpen(
              context,
              BillPayScreen(bill: bill),
              title: 'Pay ${bill.name}',
              step: 28,
            ),
          ),
      if (!signedIn && billsOn) ..._categoryTiles(context),
    ];
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
        if (!billsOn)
          const KpTip(
            tone: KpTipTone.info,
            child: Text('Bill payments are turned off right now.'),
          ),
        if (platformServices.isNotEmpty) ...[
          const KpSectionHeader(title: 'Services'),
          const SizedBox(height: 8),
          for (final service in platformServices) ...[
            _PlatformServiceTile(service: service),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (billsOn && signedIn && schoolsOn) const _LiveBillers(),
        if (payTiles.isNotEmpty) ...[
          _ServiceGrid(tiles: payTiles),
          const SizedBox(height: 16),
        ],
        if (billsOn && signedIn && schoolsOn)
          const KpTip(
            tone: KpTipTone.gold,
            child: Text('School fees are paid from your KumPay wallet.'),
          ),
        if (billsOn) const _AutopayCard(),
        if (!signedIn && billsOn) ...[
          if (_billOn(context, demoBills[0]))
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

  bool _billOn(BuildContext context, KpBill bill) {
    if (!FeatureFlagsScope.enabled(context, AppFeature.bills)) return false;
    final feature = AppFeature.forBillId(bill.id);
    if (feature == null) return true;
    return FeatureFlagsScope.enabled(context, feature);
  }

  KpServiceTone _billTone(String id) {
    return switch (id) {
      'eneo' => KpServiceTone.gold,
      'camwater' => KpServiceTone.info,
      'canal' => KpServiceTone.rose,
      _ => KpServiceTone.neutral,
    };
  }

  List<Widget> _categoryTiles(BuildContext context) {
    return [
      if (FeatureFlagsScope.enabled(context, AppFeature.airtime))
        KpServiceTile(
          label: 'Airtime',
          icon: Icons.smartphone_rounded,
          onTap: () => _soon(context, 'Airtime top-up'),
        ),
      if (FeatureFlagsScope.enabled(context, AppFeature.internet))
        KpServiceTile(
          label: 'Internet',
          icon: Icons.wifi_rounded,
          tone: KpServiceTone.info,
          onTap: () => _soon(context, 'Internet bundles'),
        ),
      if (FeatureFlagsScope.enabled(context, AppFeature.schoolFees))
        KpServiceTile(
          label: 'School fees',
          icon: Icons.school_outlined,
          tone: KpServiceTone.gold,
          maxLines: 2,
          onTap: () => _soon(context, 'School fees'),
        ),
      if (FeatureFlagsScope.enabled(context, AppFeature.taxes))
        KpServiceTile(
          label: 'Taxes',
          icon: Icons.account_balance_outlined,
          tone: KpServiceTone.neutral,
          onTap: () => _soon(context, 'Tax payments'),
        ),
    ];
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

/// Four compact actions per row, the same shape as Internet and School fees.
class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.tiles});

  final List<Widget> tiles;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += _columns) {
      final end = i + _columns > tiles.length ? tiles.length : i + _columns;
      final slice = tiles.sublist(i, end);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 14));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final tile in slice) Expanded(child: tile),
            for (var n = slice.length; n < _columns; n++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }
    return Column(children: rows);
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
  bool _busy = false;
  String? _error;

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

  Future<void> _pay(int amount) async {
    final signedIn = AuthScope.maybeRead(context)?.sessionToken != null;
    if (!signedIn) {
      kpOpen(
        context,
        BillSuccessScreen(bill: widget.bill, amount: amount),
        title: 'Payment successful',
        step: 28,
      );
      return;
    }
    final repo = moneyRepo(context);
    if (repo == null) return;
    final kyc = AuthScope.maybeRead(context)?.user?.kyc;
    final enabled = billFeatureEnabled(context, widget.bill.id);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await runMoneyMovement(
        context,
        kind: TransactionKind.bill,
        amount: amount.toDouble(),
        currency: 'XAF',
        biller: widget.bill.id,
        action: ({mfaCode, challengeId}) => repo.payBill(
          biller: widget.bill.id,
          reference: _reference.text.trim(),
          amount: amount.toDouble(),
          kyc: kyc,
          featureEnabled: enabled,
          mfaCode: mfaCode,
          challengeId: challengeId,
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (receipt == null) return;
      kpOpen(
        context,
        BillSuccessScreen(bill: widget.bill, amount: amount),
        title: 'Payment successful',
        step: 28,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException
            ? (error.status == 404
                ? '${widget.bill.name} is not open for payments yet.'
                : error.message)
            : "Couldn't complete that payment.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount =
        int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (!billFeatureEnabled(context, widget.bill.id)) {
      return KpPage(
        bottomNav: kpAppNav(context, active: KpTab.pay),
        header: KpSimpleHeader(
          title: widget.bill.name,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        children: [
          KpTip(
            tone: KpTipTone.info,
            child: Text('${widget.bill.name} is turned off right now.'),
          ),
        ],
      );
    }

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.pay),
      header: KpSimpleHeader(
        title: widget.bill.name,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: _busy
            ? 'Paying…'
            : 'Pay ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} FCFA',
        onTap: _busy ? null : () => _pay(amount),
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
                child: Icon(
                  widget.bill.icon,
                  size: 22,
                  color: KpColors.goldDeep,
                ),
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: KpColors.ink2, fontSize: 9.5),
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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
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
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
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
                          onTap: () => kpBackToStart(context),
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

/// Shows the tenant's autopay services only after they enable the feature.
class _AutopayCard extends StatefulWidget {
  const _AutopayCard();

  @override
  State<_AutopayCard> createState() => _AutopayCardState();
}

class _AutopayCardState extends State<_AutopayCard> {
  @override
  void initState() {
    super.initState();
    autopayController.addListener(_onPlan);
    autopayController.ensureLoaded(moneyRepo(context));
  }

  @override
  void dispose() {
    autopayController.removeListener(_onPlan);
    super.dispose();
  }

  void _onPlan() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plan = autopayController.plan;
    if (!plan.enabled) return const SizedBox.shrink();
    final rules = [
      for (final rule in plan.rules)
        if (billFeatureEnabled(context, rule.serviceId)) rule,
    ];
    if (rules.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
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
                KpPill(
                  label:
                      rules.length == 1 ? '1 active' : '${rules.length} active',
                  tone: KpPillTone.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < rules.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _AutopayRuleRow(rule: rules[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _AutopayRuleRow extends StatelessWidget {
  const _AutopayRuleRow({required this.rule});

  final AutopayRule rule;

  @override
  Widget build(BuildContext context) {
    final bill = demoBills.cast<KpBill?>().firstWhere(
          (item) => item?.id == rule.serviceId,
          orElse: () => null,
        );
    return InkWell(
      onTap: bill == null
          ? () => kpOpen(context, const AutopayPage(), title: 'Autopay')
          : () => kpOpen(
                context,
                BillPayScreen(bill: bill),
                title: 'Pay ${bill.name}',
                step: 28,
              ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              bill?.icon ?? Icons.receipt_long_outlined,
              size: 17,
              color: KpColors.goldDeep,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.serviceName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                  ),
                  Text(
                    rule.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: KpColors.muted,
            ),
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
    final schoolsOn =
        FeatureFlagsScope.enabled(context, AppFeature.schoolFees) &&
            FeatureFlagsScope.enabled(context, AppFeature.bills);
    if (schools != null && repo != null && schoolsOn) {
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
              .where(
                (school) =>
                    school.name.toLowerCase().contains(query.toLowerCase()) ||
                    school.code.toLowerCase().contains(query.toLowerCase()),
              )
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
                            builder: (_) => FeePayPage(
                              repository: repo!,
                              institution: school,
                            ),
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
    final matches = demoBills.where((b) {
      final feature = AppFeature.forBillId(b.id);
      final enabled = FeatureFlagsScope.enabled(context, AppFeature.bills) &&
          (feature == null || FeatureFlagsScope.enabled(context, feature));
      if (!enabled) return false;
      return b.name.toLowerCase().contains(query.toLowerCase()) ||
          b.category.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Container(
      color: KpColors.canvas,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (matches.isEmpty)
            Center(
              child: Text(
                'No billers match “$query”.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: KpColors.muted),
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
                          builder: (_) =>
                              FeePayPage(repository: repo, institution: school),
                        ),
                      ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KpRadius.md),
                  border: Border.all(color: KpColors.line),
                ),
                child: Text(
                  school.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PlatformServiceTile extends StatelessWidget {
  const _PlatformServiceTile({required this.service});

  final PlatformService service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(KpRadius.md),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ServicePayPage(service: service),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              ServiceLogo(service: service, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: KpColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
