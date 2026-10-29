import '../../data/demo.dart';

/// One platform cap for a calendar period.
class PeriodLimit {
  const PeriodLimit({
    required this.period,
    this.limit,
    this.used,
    this.remaining,
  });

  /// `monthly`, `quarterly`, or `annual`.
  final String period;
  final double? limit;
  final double? used;
  final double? remaining;

  String get title => switch (period) {
        'monthly' => 'Monthly',
        'quarterly' => 'Quarterly',
        'annual' => 'Annual',
        _ => period,
      };

  static PeriodLimit? tryParse(String period, Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    double? number(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    final parsed = PeriodLimit(
      period: period,
      limit: number(json['limit']),
      used: number(json['used']),
      remaining: number(json['remaining']),
    );
    if (parsed.limit == null &&
        parsed.used == null &&
        parsed.remaining == null) {
      return null;
    }
    return parsed;
  }

  String describe(String Function(double) format) {
    final parts = <String>[
      if (limit != null) 'limit ${format(limit!)}',
      if (used != null) 'used ${format(used!)}',
      if (remaining != null) 'left ${format(remaining!)}',
    ];
    if (parts.isEmpty) return title;
    return '$title ${parts.join(', ')}';
  }
}

/// Spending caps the platform sets for the signed-in account.
///
/// The periods that govern a payment are monthly, quarterly, and annual.
/// They are read again at payment time, so a change on the platform applies
/// to the next debit without an app update.
class AccountLimits {
  const AccountLimits({
    required this.currency,
    this.tier,
    this.perTransaction,
    this.monthly,
    this.quarterly,
    this.annual,
    this.dailyLimit,
    this.dailyUsed,
    this.remaining,
  });

  final String currency;
  final String? tier;
  final double? perTransaction;
  final PeriodLimit? monthly;
  final PeriodLimit? quarterly;
  final PeriodLimit? annual;

  /// Older payloads used a single remaining figure. Still honored when present.
  final double? dailyLimit;
  final double? dailyUsed;
  final double? remaining;

  static AccountLimits? tryParse(Object? raw) {
    if (raw is! Map) return null;
    return AccountLimits.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  factory AccountLimits.fromJson(Map<String, dynamic> json) {
    double? number(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return AccountLimits(
      currency: json['currency']?.toString().toUpperCase() ?? 'XAF',
      tier: json['tier']?.toString(),
      perTransaction: number(json['perTransaction']),
      monthly: PeriodLimit.tryParse('monthly', json['monthly']),
      quarterly: PeriodLimit.tryParse('quarterly', json['quarterly']),
      annual: PeriodLimit.tryParse('annual', json['annual']),
      dailyLimit: number(json['dailyLimit']),
      dailyUsed: number(json['dailyUsed']),
      remaining: number(json['remaining']),
    );
  }

  PeriodLimit? get _headline => monthly ?? quarterly ?? annual;

  /// Short label for the profile stat. Prefers the monthly cap.
  String get compact {
    final cap = _headline?.limit ?? dailyLimit;
    if (cap == null) return '—';
    if (currency == 'USD') return '\$${cap.toStringAsFixed(0)}';
    if (cap >= 1000000) {
      final millions = cap / 1000000;
      final text = millions == millions.roundToDouble()
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1);
      return '${text}M FCFA';
    }
    return formatXaf(cap);
  }

  String format(double amount) {
    if (currency == 'USD') return '\$${amount.toStringAsFixed(2)}';
    return formatXaf(amount);
  }

  /// Why [amount] cannot be spent, or null when every period still allows it.
  ///
  /// Caps in another currency are left to the server.
  String? blockReason(double amount, String requestCurrency) {
    if (currency.toUpperCase() != requestCurrency.toUpperCase()) return null;
    final each = perTransaction;
    if (each != null && amount > each) {
      return 'This is above your per-transaction limit of ${format(each)}.';
    }
    for (final period in [monthly, quarterly, annual]) {
      final left = period?.remaining;
      if (left != null && amount > left) {
        return 'This is above your remaining ${period!.title.toLowerCase()} limit of ${format(left)}.';
      }
    }
    final left = remaining;
    if (left != null && amount > left) {
      return 'This is above your remaining limit of ${format(left)}.';
    }
    return null;
  }

  String get summary {
    final lines = <String>[
      if (tier != null && tier!.isNotEmpty) tier!,
      for (final period in [monthly, quarterly, annual])
        if (period != null) period.describe(format),
      if (perTransaction != null) 'Per payment ${format(perTransaction!)}',
      if (monthly == null &&
          quarterly == null &&
          annual == null &&
          dailyLimit != null)
        'Limit ${format(dailyLimit!)}',
      if (remaining != null &&
          monthly == null &&
          quarterly == null &&
          annual == null)
        'Left ${format(remaining!)}',
    ];
    if (lines.isEmpty) return 'Limits are set by the platform.';
    return lines.join('\n');
  }
}
