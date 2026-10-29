import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_config.dart';
import '../../features/money/live_money.dart';
import '../../features/transactions/transaction_authorizer.dart';
import '../../features/transactions/transaction_gate.dart';
import '../../state/auth_scope.dart';
import '../../state/feature_flags_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'platform_service.dart';

/// Pays a service whose name, logo, and inputs were defined by the platform.
class ServicePayPage extends StatefulWidget {
  const ServicePayPage({super.key, required this.service});

  final PlatformService service;

  @override
  State<ServicePayPage> createState() => _ServicePayPageState();
}

class _ServicePayPageState extends State<ServicePayPage> {
  final _inputs = <ServiceFieldKey, TextEditingController>{};
  String? _choice;
  bool _busy = false;
  String? _error;
  String? _receipt;

  @override
  void dispose() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _input(ServiceFieldKey key) {
    return _inputs.putIfAbsent(key, TextEditingController.new);
  }

  PlatformService _live(BuildContext context) {
    final catalog = FeatureFlagsScope.maybeOf(context)?.snapshot.services;
    if (catalog == null) return widget.service;
    for (final service in catalog) {
      if (service.id == widget.service.id) return service;
    }
    return widget.service;
  }

  bool _stillOffered(BuildContext context) {
    final catalog = FeatureFlagsScope.maybeOf(context)?.snapshot.services;
    if (catalog == null) return true;
    return catalog.any((service) => service.id == widget.service.id);
  }

  Future<void> _pay(PlatformService service) async {
    final values = <String, String>{};
    for (final field in service.fields) {
      if (field.key == ServiceFieldKey.type && field.options.isNotEmpty) {
        final choice = _choice?.trim() ?? '';
        if (choice.isEmpty) {
          setState(() => _error = 'Choose ${field.label}.');
          return;
        }
        values[field.key.wire] = choice;
        continue;
      }
      final text = _input(field.key).text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Enter ${field.label}.');
        return;
      }
      values[field.key.wire] = text;
    }
    final amount = service.resolveAmount(values['amount']);
    if (amount == null) {
      setState(
        () => _error = 'This service has no amount the platform can debit.',
      );
      return;
    }

    final repo = moneyRepo(context);
    if (repo == null) {
      setState(() => _error = 'Sign in to pay ${service.name}.');
      return;
    }
    final kyc = AuthScope.maybeRead(context)?.user?.kyc;
    final enabled = billFeatureEnabled(context, service.id);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await runMoneyMovement(
        context,
        kind: TransactionKind.bill,
        amount: amount,
        currency: service.currency,
        biller: service.id,
        action: ({mfaCode, challengeId}) => repo.payService(
          serviceId: service.id,
          amount: amount,
          currency: service.currency,
          fields: values,
          kyc: kyc,
          featureEnabled: enabled,
          mfaCode: mfaCode,
          challengeId: challengeId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _receipt = result?.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException
            ? error.message
            : "Couldn't complete that payment.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _live(context);
    if (!_stillOffered(context)) {
      return KpPage(
        bottomNav: kpAppNav(context, active: KpTab.pay),
        header: KpSimpleHeader(
          title: widget.service.name,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        children: [
          KpTip(
            tone: KpTipTone.info,
            child: Text('${widget.service.name} is turned off right now.'),
          ),
        ],
      );
    }

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.pay),
      header: KpSimpleHeader(
        title: service.name,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: _busy ? 'Paying…' : 'Pay',
        onTap: _busy || _receipt != null ? null : () => _pay(service),
      ),
      children: [
        _ServiceHeading(service: service),
        const SizedBox(height: 16),
        if (!service.asksForAmount && service.fixedAmount != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Amount ${service.fixedAmount} ${service.currency}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        for (final field in service.fields) ...[
          if (field.key == ServiceFieldKey.type && field.options.isNotEmpty)
            _ChoiceField(
              label: field.label,
              options: field.options,
              selected: _choice,
              onSelected: (value) => setState(() => _choice = value),
            )
          else
            KpTextField(
              label: field.label,
              controller: _input(field.key),
              keyboardType: field.key == ServiceFieldKey.amount
                  ? TextInputType.number
                  : TextInputType.text,
              prefixIcon: switch (field.key) {
                ServiceFieldKey.amount => Icons.payments_outlined,
                ServiceFieldKey.receiver => Icons.person_outline_rounded,
                ServiceFieldKey.type => Icons.category_outlined,
              },
            ),
          const SizedBox(height: 12),
        ],
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'KumPay debits your balance. A provider is contacted only when that balance does not cover the amount.',
          ),
        ),
        if (_receipt != null) ...[
          const SizedBox(height: 12),
          KpTip(tone: KpTipTone.success, child: Text(_receipt!)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
      ],
    );
  }
}

class ServiceLogo extends StatelessWidget {
  const ServiceLogo({super.key, required this.service, this.size = 46});

  final PlatformService service;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = service.logoUrl(kApiBase);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: KpColors.line),
      ),
      child: url == null
          ? const Icon(Icons.account_balance_outlined, color: KpColors.primary)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_outlined,
                color: KpColors.primary,
              ),
            ),
    );
  }
}

class _ServiceHeading extends StatelessWidget {
  const _ServiceHeading({required this.service});

  final PlatformService service;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ServiceLogo(service: service),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            service.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpFieldLabel(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}
