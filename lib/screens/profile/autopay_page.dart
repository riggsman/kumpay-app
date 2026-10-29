import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../features/autopay/autopay_controller.dart';
import '../../features/autopay/autopay_plan.dart';
import '../../features/money/live_money.dart';
import '../../features/transactions/transaction_gate.dart';
import '../../state/feature_flags_scope.dart';
import '../../features/feature_flags/app_feature.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Profile screen where the tenant turns autopay on and attaches services.
class AutopayPage extends StatefulWidget {
  const AutopayPage({super.key});

  @override
  State<AutopayPage> createState() => _AutopayPageState();
}

class _AutopayPageState extends State<AutopayPage> {
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '5');
  final _threshold = TextEditingController(text: '5000');

  var _adding = false;
  var _when = AutopayWhen.below;
  String? _serviceId;
  String? _error;

  @override
  void initState() {
    super.initState();
    autopayController.addListener(_onPlan);
    autopayController.ensureLoaded(moneyRepo(context));
  }

  @override
  void dispose() {
    autopayController.removeListener(_onPlan);
    _amount.dispose();
    _day.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _onPlan() {
    if (mounted) setState(() {});
  }

  List<KpBill> get _services =>
      demoBills.where((bill) => billFeatureEnabled(context, bill.id)).toList();

  Future<void> _savePlan(AutopayPlan next) async {
    try {
      await autopayController.update(moneyRepo(context), next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Could not save autopay.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: KpColors.primary,
        ),
      );
    }
  }

  void _openForm() {
    final services = _services;
    setState(() {
      _adding = true;
      _error = null;
      _serviceId = services.isEmpty ? null : services.first.id;
      _when = services.isNotEmpty && services.first.id == 'eneo'
          ? AutopayWhen.below
          : AutopayWhen.monthly;
      _amount.clear();
      _day.text = '5';
      _threshold.text = '5000';
    });
  }

  Future<void> _addRule() async {
    final serviceId = _serviceId;
    final bill = demoBills.cast<KpBill?>().firstWhere(
          (bill) => bill?.id == serviceId,
          orElse: () => null,
        );
    final amount = _money(_amount.text);
    if (bill == null) {
      setState(() => _error = 'Choose a service.');
      return;
    }
    if (amount == null) {
      setState(() => _error = 'Enter the amount to pay.');
      return;
    }
    int? day;
    double? threshold;
    if (_when == AutopayWhen.monthly) {
      day = int.tryParse(_day.text.trim());
      if (day == null || day < 1 || day > 28) {
        setState(() => _error = 'Use a day from 1 to 28.');
        return;
      }
    } else {
      threshold = _money(_threshold.text);
      if (threshold == null) {
        setState(() => _error = 'Enter the balance that starts the payment.');
        return;
      }
    }
    final plan = autopayController.plan;
    final rule = AutopayRule(
      id: plan.rules
              .where((item) => item.serviceId == bill.id)
              .map((item) => item.id)
              .firstOrNull ??
          'ap_${bill.id}',
      serviceId: bill.id,
      serviceName: _serviceLabel(bill),
      amount: amount,
      when: _when,
      dayOfMonth: day,
      threshold: threshold,
    );
    final rules = [
      for (final item in plan.rules)
        if (item.serviceId != bill.id) item,
      rule,
    ];
    await _savePlan(plan.copyWith(enabled: true, rules: rules));
    if (!mounted) return;
    setState(() {
      _adding = false;
      _error = null;
    });
  }

  Future<void> _remove(AutopayRule rule) {
    final plan = autopayController.plan;
    return _savePlan(
      plan.copyWith(
        rules: [
          for (final item in plan.rules)
            if (item.id != rule.id) item,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = autopayController.plan;
    final billsOn = FeatureFlagsScope.enabled(context, AppFeature.bills);
    final services = _services;
    final visible = [
      for (final rule in plan.rules)
        if (billFeatureEnabled(context, rule.serviceId)) rule,
    ];

    return KpPage(
      header: KpSimpleHeader(
        title: 'Autopay',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        KpToggleRow(
          title: 'Enable autopay',
          subtitle: 'Only you can turn this on',
          icon: Icons.event_repeat_rounded,
          value: plan.enabled && billsOn,
          onChanged: billsOn
              ? (value) => _savePlan(plan.copyWith(enabled: value))
              : (_) {},
        ),
        if (!billsOn)
          const KpTip(
            tone: KpTipTone.info,
            child: Text('Bill payments are turned off right now.'),
          )
        else if (!plan.enabled)
          Text(
            'Turn autopay on, then add each service, the amount, and when KumPay should pay it.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.muted,
                  fontSize: 11,
                  height: 1.4,
                ),
          )
        else ...[
          if (visible.isEmpty && !_adding)
            Text(
              'No services yet. Add one and the amount you want paid automatically.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
            ),
          for (final rule in visible) ...[
            _RuleRow(rule: rule, onRemove: () => _remove(rule)),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 8),
          if (_adding)
            _AddForm(
              services: services,
              serviceId: _serviceId,
              when: _when,
              amount: _amount,
              day: _day,
              threshold: _threshold,
              error: _error,
              onService: (id) => setState(() {
                _serviceId = id;
                _when = id == 'eneo' ? AutopayWhen.below : AutopayWhen.monthly;
                _error = null;
              }),
              onWhen: (when) => setState(() {
                _when = when;
                _error = null;
              }),
              onCancel: () => setState(() {
                _adding = false;
                _error = null;
              }),
              onSave: services.isEmpty ? null : _addRule,
            )
          else
            KpButton(
              label: 'Add a service',
              icon: Icons.add_rounded,
              onTap: services.isEmpty ? null : _openForm,
            ),
        ],
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.onRemove});

  final AutopayRule rule;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bill = demoBills.cast<KpBill?>().firstWhere(
          (item) => item?.id == rule.serviceId,
          orElse: () => null,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(bill?.icon ?? Icons.receipt_long_outlined,
              size: 18, color: KpColors.goldDeep),
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
                        fontSize: 11,
                      ),
                ),
                Text(
                  rule.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.muted,
                        fontSize: 9.5,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: KpColors.muted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AddForm extends StatelessWidget {
  const _AddForm({
    required this.services,
    required this.serviceId,
    required this.when,
    required this.amount,
    required this.day,
    required this.threshold,
    required this.error,
    required this.onService,
    required this.onWhen,
    required this.onCancel,
    required this.onSave,
  });

  final List<KpBill> services;
  final String? serviceId;
  final AutopayWhen when;
  final TextEditingController amount;
  final TextEditingController day;
  final TextEditingController threshold;
  final String? error;
  final ValueChanged<String> onService;
  final ValueChanged<AutopayWhen> onWhen;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KpFieldLabel('Service'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final bill in services)
              _Choice(
                label: _serviceLabel(bill),
                selected: bill.id == serviceId,
                onTap: () => onService(bill.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const KpFieldLabel('When'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Choice(
              label: 'Every month',
              selected: when == AutopayWhen.monthly,
              onTap: () => onWhen(AutopayWhen.monthly),
            ),
            _Choice(
              label: 'When it falls below',
              selected: when == AutopayWhen.below,
              onTap: () => onWhen(AutopayWhen.below),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (when == AutopayWhen.monthly)
          KpTextField(
            label: 'Day of the month',
            hint: '5',
            controller: day,
            keyboardType: TextInputType.number,
          )
        else
          KpTextField(
            label: 'Start when balance is below',
            hint: '5 000',
            controller: threshold,
            keyboardType: TextInputType.number,
          ),
        const SizedBox(height: 10),
        KpTextField(
          label: 'Amount to pay',
          hint: when == AutopayWhen.monthly ? '18 000' : '5 000',
          controller: amount,
          keyboardType: TextInputType.number,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(color: KpColors.danger, fontSize: 11),
          ),
        ],
        const SizedBox(height: 12),
        KpButton(label: 'Save service', onTap: onSave),
        const SizedBox(height: 6),
        Center(child: KpTextLink('Cancel', onTap: onCancel)),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? KpColors.primary : KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KpRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.pill),
            border: Border.all(
              color: selected ? KpColors.primary : KpColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFFFDF9EE) : KpColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
    );
  }
}

String _serviceLabel(KpBill bill) {
  return switch (bill.id) {
    'eneo' => 'ENEO prepaid',
    'canal' => 'Canal+ Premium',
    _ => bill.name,
  };
}

double? _money(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value <= 0) return null;
  return value;
}
