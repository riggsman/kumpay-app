import 'package:flutter/material.dart';

import '../theme/kp_theme.dart';

class KpLogoMark extends StatelessWidget {
  const KpLogoMark({super.key, this.size = 36, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: KpColors.gradientGold,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: KpColors.gold.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'K',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: KpColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.5,
              height: 1,
            ),
      ),
    );
  }
}

class KpBrand extends StatelessWidget {
  const KpBrand({super.key, this.light = false, this.compact = false});

  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KpLogoMark(size: compact ? 28 : 32),
        const SizedBox(width: 9),
        Text(
          'KumPay',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: light ? const Color(0xFFFDF9EE) : KpColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 18 : 20,
                letterSpacing: -0.6,
              ),
        ),
      ],
    );
  }
}

class KpShieldMark extends StatelessWidget {
  const KpShieldMark(
      {super.key, this.size = 20, this.color = KpColors.primary});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.verified_user_rounded, size: size, color: color);
  }
}
