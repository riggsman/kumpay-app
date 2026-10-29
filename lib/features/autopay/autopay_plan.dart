import '../../data/demo.dart';

/// When KumPay should run an automatic payment.
///
/// These are the two schedules the bills screen already showed: a fixed day
/// each month, or a top-up once a balance falls below a threshold.
enum AutopayWhen {
  monthly,
  below;

  static AutopayWhen? parse(Object? raw) {
    return switch (raw?.toString()) {
      'monthly' => AutopayWhen.monthly,
      'below' => AutopayWhen.below,
      _ => null,
    };
  }
}

/// One service the tenant has asked KumPay to pay on its own.
class AutopayRule {
  const AutopayRule({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.amount,
    required this.when,
    this.currency = 'XAF',
    this.dayOfMonth,
    this.threshold,
  });

  final String id;
  final String serviceId;
  final String serviceName;

  /// Amount to pay, in major units.
  final double amount;
  final String currency;
  final AutopayWhen when;

  /// Day of the month for [AutopayWhen.monthly]. Clamped to 1–28.
  final int? dayOfMonth;

  /// Balance that triggers [AutopayWhen.below], in major units.
  final double? threshold;

  String get detail {
    final paid = formatXaf(amount);
    if (when == AutopayWhen.monthly) {
      return 'Every ${dayOrdinal(dayOfMonth ?? 1)} · $paid';
    }
    final line = 'When below ${formatXaf(threshold ?? amount)}';
    if (threshold != null && threshold != amount) return '$line · pay $paid';
    return line;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'amount': amount,
        'currency': currency,
        'when': when.name,
        if (when == AutopayWhen.monthly) 'dayOfMonth': dayOfMonth,
        if (when == AutopayWhen.below) 'threshold': threshold,
      };

  static AutopayRule? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final when = AutopayWhen.parse(raw['when']);
    final amount = (raw['amount'] as num?)?.toDouble();
    final serviceId = raw['serviceId']?.toString() ?? '';
    final serviceName = raw['serviceName']?.toString() ?? '';
    if (when == null || amount == null || amount <= 0) return null;
    if (serviceId.isEmpty || serviceName.isEmpty) return null;
    final day = (raw['dayOfMonth'] as num?)?.toInt();
    final threshold = (raw['threshold'] as num?)?.toDouble();
    if (when == AutopayWhen.monthly && (day == null || day < 1 || day > 28)) {
      return null;
    }
    if (when == AutopayWhen.below && (threshold == null || threshold <= 0)) {
      return null;
    }
    final id = raw['id']?.toString();
    return AutopayRule(
      id: id == null || id.isEmpty ? 'ap_$serviceId' : id,
      serviceId: serviceId,
      serviceName: serviceName,
      amount: amount,
      currency: raw['currency']?.toString() ?? 'XAF',
      when: when,
      dayOfMonth: day,
      threshold: threshold,
    );
  }
}

/// The tenant's autopay switch and the services they attached to it.
class AutopayPlan {
  const AutopayPlan({required this.enabled, this.rules = const []});

  /// Off until the tenant turns it on in Profile.
  static const off = AutopayPlan(enabled: false);

  final bool enabled;
  final List<AutopayRule> rules;

  bool get active => enabled && rules.isNotEmpty;

  AutopayPlan copyWith({bool? enabled, List<AutopayRule>? rules}) {
    return AutopayPlan(
      enabled: enabled ?? this.enabled,
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rules': [for (final rule in rules) rule.toJson()],
      };

  factory AutopayPlan.fromJson(Map<String, dynamic> json) {
    final raw = json['rules'];
    return AutopayPlan(
      enabled: json['enabled'] == true,
      rules: [
        if (raw is List)
          for (final entry in raw)
            if (AutopayRule.tryParse(entry) case final rule?) rule,
      ],
    );
  }
}

/// `5` → `5th`. Used by the monthly schedule line.
String dayOrdinal(int day) {
  final mod100 = day % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${day}th';
  return switch (day % 10) {
    1 => '${day}st',
    2 => '${day}nd',
    3 => '${day}rd',
    _ => '${day}th',
  };
}
