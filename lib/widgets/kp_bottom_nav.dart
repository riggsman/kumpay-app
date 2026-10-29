import 'package:flutter/material.dart';

import '../theme/kp_theme.dart';

class KpBottomNav extends StatelessWidget {
  const KpBottomNav({
    super.key,
    this.index = 0,
    this.onTap,
    this.onSend,
  });

  final int index;
  final ValueChanged<int>? onTap;
  final VoidCallback? onSend;

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),
    (Icons.account_balance_wallet_outlined, 'Wallet'),
    (Icons.send_rounded, 'Send'),
    (Icons.receipt_long_outlined, 'Pay'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      decoration: const BoxDecoration(
        color: KpColors.surface,
        border: Border(top: BorderSide(color: KpColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D142A23),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _NavItem(
                icon: _items[i].$1,
                label: _items[i].$2,
                active: index == i,
                center: i == 2,
                onTap: () {
                  if (i == 2) {
                    onSend?.call();
                  } else {
                    onTap?.call(i);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.center,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool center;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (center) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: KpColors.gradientGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KpColors.gold.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: KpColors.surface, width: 3),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 19,
                  color: KpColors.primaryDark,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final color = active ? KpColors.primary : KpColors.muted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 28,
            width: 40,
            alignment: Alignment.center,
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 8.5,
                ),
          ),
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: active ? KpColors.gold : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
