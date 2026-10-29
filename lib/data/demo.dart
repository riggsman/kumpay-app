import 'package:flutter/material.dart';

/// Demo data used by the UI/UX kit. The production app will hydrate these
/// models from the KumPay backend instead.
class KpUser {
  const KpUser({
    required this.name,
    required this.initials,
    required this.phone,
    required this.accountNumber,
    required this.kyc,
    required this.memberSince,
    required this.xaf,
    required this.usd,
  });

  final String name;
  final String initials;
  final String phone;
  final String accountNumber;
  final String kyc;
  final String memberSince;
  final double xaf;
  final double usd;
}

const demoUser = KpUser(
  name: 'Aïcha Ngono',
  initials: 'AN',
  phone: '+237 677 12 34 56',
  accountNumber: '2048 3391 0021',
  kyc: 'Verified',
  memberSince: 'Mar 2026',
  xaf: 248500,
  usd: 120.50,
);

class KpTransaction {
  const KpTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.incoming,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String currency;
  final bool incoming;
  final IconData icon;
}

const demoTransactions = <KpTransaction>[
  KpTransaction(
    title: 'MoMo top-up',
    subtitle: 'Today · 09:14 · MTN MoMo',
    amount: '+50,000',
    currency: 'FCFA',
    incoming: true,
    icon: Icons.south_west_rounded,
  ),
  KpTransaction(
    title: 'ENEO prepaid',
    subtitle: 'Yesterday · 18:02 · incl. 100 FCFA fee',
    amount: '-12,500',
    currency: 'FCFA',
    incoming: false,
    icon: Icons.bolt_rounded,
  ),
  KpTransaction(
    title: 'Netflix.com',
    subtitle: '20 Oct · 07:45 · Virtual card •4821',
    amount: '-9.99',
    currency: 'USD',
    incoming: false,
    icon: Icons.play_circle_outline_rounded,
  ),
  KpTransaction(
    title: 'To Clarisse Fouda',
    subtitle: '19 Oct · 13:30 · KumPay',
    amount: '-20,000',
    currency: 'FCFA',
    incoming: false,
    icon: Icons.north_east_rounded,
  ),
  KpTransaction(
    title: 'Bank transfer',
    subtitle: '19 Oct · 10:12 · Afriland First Bank',
    amount: '-150,000',
    currency: 'FCFA',
    incoming: false,
    icon: Icons.account_balance_outlined,
  ),
];

class KpBill {
  const KpBill({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.referenceLabel,
    required this.reference,
  });

  final String id;
  final String name;
  final String category;
  final IconData icon;
  final String referenceLabel;
  final String reference;
}

const demoBills = <KpBill>[
  KpBill(
    id: 'eneo',
    name: 'ENEO Electricity',
    category: 'Prepaid · Douala',
    icon: Icons.bolt_rounded,
    referenceLabel: 'Meter number',
    reference: 'BN-88492017',
  ),
  KpBill(
    id: 'camwater',
    name: 'CAMWATER',
    category: 'Water · Yaoundé',
    icon: Icons.water_drop_outlined,
    referenceLabel: 'Contract number',
    reference: 'CW-2100448',
  ),
  KpBill(
    id: 'canal',
    name: 'Canal+',
    category: 'Cable TV · Premium',
    icon: Icons.live_tv_rounded,
    referenceLabel: 'Decoder number',
    reference: 'CN-01923845',
  ),
  KpBill(
    id: 'dstv',
    name: 'DStv',
    category: 'Cable TV · Compact',
    icon: Icons.satellite_alt_outlined,
    referenceLabel: 'Smartcard number',
    reference: 'DS-8820134',
  ),
];

const demoLanguages = <KpLanguage>[
  KpLanguage(code: 'en', name: 'English', native: 'Default'),
  KpLanguage(code: 'fr', name: 'Français', native: 'French'),
  KpLanguage(code: 'pcm', name: 'Cameroonian Pidgin', native: 'Pidgin'),
  KpLanguage(code: 'ff', name: 'Fulfulde', native: 'Northern Cameroon'),
];

class KpLanguage {
  const KpLanguage({
    required this.code,
    required this.name,
    required this.native,
  });

  final String code;
  final String name;
  final String native;
}

String formatXaf(double value) {
  final whole = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(whole[i]);
  }
  return '${buffer.toString()} FCFA';
}

String maskPhone([String phone = '+237 677 12 34 56']) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return '••• ••• ${digits.substring(digits.length - 3)}';
}
