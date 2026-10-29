import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A funding account linked to the wallet (mobile money or bank).
class LinkedAccount {
  const LinkedAccount({
    required this.id,
    required this.label,
    required this.kind,
    required this.detail,
  });

  final String id;
  final String label;

  /// `momo` or `bank`.
  final String kind;

  /// Masked number returned by the server.
  final String detail;

  String get kindLabel => kind == 'bank' ? 'Bank' : 'Mobile money';

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString().trim() ?? '',
      kind: json['kind']?.toString().trim().toLowerCase() == 'bank'
          ? 'bank'
          : 'momo',
      detail: json['detail']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind,
        'detail': detail,
      };

  static List<LinkedAccount> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          LinkedAccount.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ]
        .where((account) => account.id.isNotEmpty && account.label.isNotEmpty)
        .toList();
  }
}

/// A statement the platform has stored for this wallet.
class WalletStatement {
  const WalletStatement({
    required this.id,
    required this.period,
    required this.currency,
    required this.status,
    this.reference = '',
    this.downloadUrl = '',
  });

  final String id;

  /// `YYYY-MM`.
  final String period;
  final String currency;

  /// `pending`, `ready`, or `failed`.
  final String status;
  final String reference;
  final String downloadUrl;

  bool get isReady => status == 'ready';

  String get periodLabel {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(period);
    if (match == null) return period;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = int.tryParse(match.group(2)!) ?? 0;
    if (month < 1 || month > 12) return period;
    return '${months[month - 1]} ${match.group(1)}';
  }

  factory WalletStatement.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().trim().toLowerCase() ?? '';
    return WalletStatement(
      id: json['id']?.toString() ?? '',
      period: json['period']?.toString().trim() ?? '',
      currency: canonicalCurrency(json['currency']?.toString() ?? ''),
      status: status.isEmpty ? 'pending' : status,
      reference: json['reference']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
    );
  }

  static List<WalletStatement> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          WalletStatement.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ].where((item) => item.id.isNotEmpty).toList();
  }
}

/// Result of closing a wallet. The server decides whether the session ends.
class WalletClosure {
  const WalletClosure({
    required this.closed,
    required this.signedOut,
    required this.message,
  });

  final bool closed;
  final bool signedOut;
  final String message;

  factory WalletClosure.fromJson(Map<String, dynamic> json) {
    final message = json['message']?.toString().trim() ?? '';
    return WalletClosure(
      closed: json['closed'] == true,
      signedOut: json['signedOut'] == true,
      message: message.isEmpty ? 'Your wallet is closed.' : message,
    );
  }
}

/// Wallet preferences stored for the signed-in account.
///
/// [defaultCurrency] is chosen in the database. The app shows it and does not
/// offer an editor. [closeWalletEnabled] stays false until the database sends
/// true, which is the only case where Close wallet is shown.
class WalletSettings {
  const WalletSettings({
    required this.defaultCurrency,
    required this.closeWalletEnabled,
    required this.currencies,
    required this.accounts,
  });

  final String defaultCurrency;
  final bool closeWalletEnabled;
  final List<String> currencies;
  final List<LinkedAccount> accounts;

  static const fallback = WalletSettings(
    defaultCurrency: 'XAF',
    closeWalletEnabled: false,
    currencies: ['XAF', 'USD'],
    accounts: [],
  );

  String get defaultCurrencyLabel => currencyLabel(defaultCurrency);

  bool offers(String code) {
    final canonical = canonicalCurrency(code);
    if (currencies.isEmpty) return canonical == 'XAF' || canonical == 'USD';
    return currencies.map(canonicalCurrency).contains(canonical);
  }

  factory WalletSettings.fromJson(Map<String, dynamic> json) {
    final currencies = <String>[];
    final rawCurrencies = json['currencies'];
    if (rawCurrencies is List) {
      for (final entry in rawCurrencies) {
        final code = canonicalCurrency(entry?.toString() ?? '');
        if (code.isNotEmpty && !currencies.contains(code)) currencies.add(code);
      }
    }
    return WalletSettings(
      defaultCurrency: canonicalCurrency(
        json['defaultCurrency']?.toString() ?? 'XAF',
      ),
      closeWalletEnabled: json['closeWalletEnabled'] == true,
      currencies: currencies.isEmpty ? const ['XAF', 'USD'] : currencies,
      accounts: LinkedAccount.listFrom(json['accounts']),
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultCurrency': defaultCurrency,
        'closeWalletEnabled': closeWalletEnabled,
        'currencies': currencies,
        'accounts': [for (final account in accounts) account.toJson()],
      };

  WalletSettings copyWith({
    String? defaultCurrency,
    bool? closeWalletEnabled,
    List<String>? currencies,
    List<LinkedAccount>? accounts,
  }) {
    return WalletSettings(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      closeWalletEnabled: closeWalletEnabled ?? this.closeWalletEnabled,
      currencies: currencies ?? this.currencies,
      accounts: accounts ?? this.accounts,
    );
  }
}

/// `XAF` and `FCFA` are the same wallet. Anything else is returned uppercased.
String canonicalCurrency(String raw) {
  final value = raw.trim().toUpperCase();
  if (value.isEmpty || value == 'XAF' || value == 'FCFA') return 'XAF';
  return value;
}

String currencyLabel(String code) =>
    canonicalCurrency(code) == 'USD' ? 'USD' : 'FCFA';

/// Last wallet settings document, so the default currency is available offline.
abstract class WalletSettingsCache {
  Future<WalletSettings?> read();
  Future<void> write(WalletSettings settings);
}

class MemoryWalletSettingsCache implements WalletSettingsCache {
  WalletSettings? value;

  @override
  Future<WalletSettings?> read() async => value;

  @override
  Future<void> write(WalletSettings settings) async => value = settings;
}

class SecureWalletSettingsCache implements WalletSettingsCache {
  SecureWalletSettingsCache([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kumpay.wallet_settings';

  final FlutterSecureStorage _storage;

  @override
  Future<WalletSettings?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WalletSettings.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(WalletSettings settings) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(settings.toJson()));
    } catch (_) {
      // The next successful read still shows the value from the database.
    }
  }
}
