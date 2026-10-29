import '../../data/demo.dart';

/// Spending caps returned by the platform for the signed-in account.
class AccountLimits {
  const AccountLimits({
    required this.currency,
    this.tier,
    this.dailyLimit,
    this.dailyUsed,
    this.remaining,
    this.perTransaction,
  });

  final String currency;
  final String? tier;
  final double? dailyLimit;
  final double? dailyUsed;
  final double? remaining;
  final double? perTransaction;

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
      dailyLimit: number(json['dailyLimit']),
      dailyUsed: number(json['dailyUsed']),
      remaining: number(json['remaining']),
      perTransaction: number(json['perTransaction']),
    );
  }

  /// Short label for the profile stat, such as `2M FCFA`.
  String get compact {
    final cap = dailyLimit;
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

  /// Why [amount] cannot be spent, or null when these caps allow it.
  ///
  /// Caps in another currency are left to the server.
  String? blockReason(double amount, String requestCurrency) {
    if (currency.toUpperCase() != requestCurrency.toUpperCase()) return null;
    final each = perTransaction;
    if (each != null && amount > each) {
      return 'This is above your per-transaction limit of ${format(each)}.';
    }
    final left = remaining;
    if (left != null && amount > left) {
      return 'This is above your remaining limit of ${format(left)}.';
    }
    return null;
  }

  String get summary {
    final parts = <String>[
      if (tier != null && tier!.isNotEmpty) tier!,
      if (dailyLimit != null) 'Daily limit ${format(dailyLimit!)}',
      if (dailyUsed != null) 'Used ${format(dailyUsed!)}',
      if (remaining != null) 'Left ${format(remaining!)}',
      if (perTransaction != null) 'Per transfer ${format(perTransaction!)}',
    ];
    if (parts.isEmpty) return 'Limits are set by your verification level.';
    return parts.join(' · ');
  }
}
