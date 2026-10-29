import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/demo.dart';
import '../../data/money/money_repository.dart';
import '../../state/auth_scope.dart';
import '../../widgets/kp_controls.dart';

MoneyRepository? moneyRepo(BuildContext context) {
  final token = AuthScope.maybeRead(context)?.sessionToken;
  if (token == null || token.isEmpty) return null;
  return MoneyRepository(baseUrl: kApiBase, token: token);
}

class WalletBalanceText extends StatefulWidget {
  const WalletBalanceText({super.key, required this.fallback, this.usd = false});

  final String fallback;
  final bool usd;

  @override
  State<WalletBalanceText> createState() => _WalletBalanceTextState();
}

class _WalletBalanceTextState extends State<WalletBalanceText> {
  String? _live;

  @override
  void initState() {
    super.initState();
    final repo = moneyRepo(context);
    if (repo == null) return;
    repo.wallet().then((wallet) {
      if (!mounted) return;
      setState(() => _live = widget.usd ? wallet.usd.label : wallet.xaf.label);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => Text(_live ?? widget.fallback);
}

/// Replaces a balance string once the signed-in wallet loads.
class WalletAmount extends StatefulWidget {
  const WalletAmount({super.key, required this.fallback, required this.builder, this.usd = false});

  final String fallback;
  final bool usd;
  final Widget Function(BuildContext context, String amount) builder;

  @override
  State<WalletAmount> createState() => _WalletAmountState();
}

class _WalletAmountState extends State<WalletAmount> {
  String? _live;

  @override
  void initState() {
    super.initState();
    final repo = moneyRepo(context);
    if (repo == null) return;
    repo.wallet().then((wallet) {
      if (!mounted) return;
      setState(() => _live = widget.usd ? wallet.usd.label : wallet.xaf.label);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _live ?? widget.fallback);
}

class LiveActivityList extends StatefulWidget {
  const LiveActivityList({super.key, this.limit = 4, this.filter = 0});

  final int limit;
  final int filter;

  @override
  State<LiveActivityList> createState() => _LiveActivityListState();
}

class _LiveActivityListState extends State<LiveActivityList> {
  ActivityBook? _book;
  bool _live = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final repo = moneyRepo(context);
    _live = repo != null;
    if (repo == null) return;
    _loading = true;
    repo.activity().then((book) {
      if (!mounted) return;
      setState(() {
        _book = book;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void didUpdateWidget(covariant LiveActivityList oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!_live) {
      final demo = switch (widget.filter) {
        1 => demoTransactions.where((item) => item.incoming).toList(),
        2 => demoTransactions.where((item) => !item.incoming).toList(),
        _ => demoTransactions,
      };
      final shown = demo.take(widget.limit).toList();
      return Column(
        children: [
          for (var i = 0; i < shown.length; i++)
            KpActivityTile(
              title: shown[i].title,
              subtitle: shown[i].subtitle,
              amount: shown[i].amount,
              currency: shown[i].currency,
              incoming: shown[i].incoming,
              icon: shown[i].icon,
              showDivider: i < shown.length - 1,
            ),
        ],
      );
    }
    if (_loading) return const LinearProgressIndicator(minHeight: 2);
    final items = (_book?.items ?? const <ActivityItem>[]).where((item) {
      return switch (widget.filter) {
        1 => item.incoming,
        2 => !item.incoming,
        _ => true,
      };
    }).take(widget.limit);
    final list = items.toList();
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No wallet activity yet.'),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < list.length; i++)
          KpActivityTile(
            title: list[i].title,
            subtitle: list[i].subtitle,
            amount: list[i].amount.currency == 'USD'
                ? list[i].amount.amount.toStringAsFixed(2)
                : formatXaf(list[i].amount.amount).replaceAll(' FCFA', ''),
            currency: list[i].amount.currency == 'USD' ? 'USD' : 'FCFA',
            incoming: list[i].incoming,
            icon: list[i].incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
            showDivider: i < list.length - 1,
          ),
      ],
    );
  }
}

class LinkedPhones extends StatefulWidget {
  const LinkedPhones({super.key});

  @override
  State<LinkedPhones> createState() => _LinkedPhonesState();
}

class _LinkedPhonesState extends State<LinkedPhones> {
  List<({String number, String kind})>? _phones;

  @override
  void initState() {
    super.initState();
    final repo = moneyRepo(context);
    if (repo == null) return;
    repo.wallet().then((wallet) {
      if (mounted) setState(() => _phones = wallet.phones);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final phones = _phones;
    if (phones == null) {
      return const KpDetailCard(
        rows: [
          KpDetailRow('MTN Mobile Money', '+237 677 ••• 456'),
          KpDetailRow('Orange Money', '+237 699 ••• 118'),
          KpDetailRow('Afriland First Bank', '•••• 3391'),
        ],
      );
    }
    if (phones.isEmpty) {
      return const KpDetailCard(rows: [KpDetailRow('Phone numbers', 'None on this account')]);
    }
    return KpDetailCard(
      rows: [
        for (final phone in phones)
          KpDetailRow(phone.kind == 'topup' ? 'Top-up number' : 'Primary number', phone.number),
      ],
    );
  }
}
