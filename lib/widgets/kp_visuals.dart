import 'package:flutter/material.dart';

import '../theme/kp_theme.dart';
import 'kp_controls.dart';
import 'kp_shell.dart';

class KpDeviceIllustration extends StatelessWidget {
  const KpDeviceIllustration({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: KpColors.softGreen,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            left: size * 0.3,
            top: size * 0.16,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: size * 0.32,
                height: size * 0.62,
                decoration: BoxDecoration(
                  color: KpColors.primary,
                  borderRadius: BorderRadius.circular(size * 0.06),
                  boxShadow: [
                    BoxShadow(
                      color: KpColors.primary.withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: size * 0.09,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.lock_rounded,
                      size: size * 0.12,
                      color: KpColors.gold,
                    ),
                    const Spacer(),
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: size * 0.2,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.38,
              height: size * 0.38,
              decoration: BoxDecoration(
                color: KpColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: KpColors.surface, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: KpColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: size * 0.17,
                color: KpColors.primaryDark,
              ),
            ),
          ),
          Positioned(
            left: size * 0.12,
            top: size * 0.18,
            child: _Dot(size: size * 0.035, color: KpColors.gold),
          ),
          Positioned(
            left: size * 0.2,
            bottom: size * 0.2,
            child: _Dot(size: size * 0.02, color: KpColors.primaryLight),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class KpSuccessHero extends StatelessWidget {
  const KpSuccessHero({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.compact = false,
  });

  final String title;
  final String body;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.fromLTRB(22, compact ? 12 : 22, 22, compact ? 24 : 32),
      decoration: const BoxDecoration(
        gradient: KpColors.gradientForest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KpColors.gold.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            children: [
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onBack ?? () => kpBack(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFFFDF9EE),
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              Container(
                width: compact ? 66 : 78,
                height: compact ? 66 : 78,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Container(
                    width: compact ? 48 : 56,
                    height: compact ? 48 : 56,
                    decoration: const BoxDecoration(
                      color: KpColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: compact ? 27 : 31,
                      color: KpColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFDF9EE),
                      fontWeight: FontWeight.w800,
                      fontSize: 23,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC7D8CE),
                      fontSize: 11,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KpRedirectAlert extends StatelessWidget {
  const KpRedirectAlert({
    super.key,
    this.seconds = 3,
    this.onDismiss,
    this.onNow,
  });

  final int seconds;
  final VoidCallback? onDismiss;
  final VoidCallback? onNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KpColors.successSoft,
        borderRadius: BorderRadius.circular(KpRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: KpColors.success),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Returning to Home',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Redirecting in ${seconds}s…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.ink2,
                        fontSize: 9.5,
                      ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    minHeight: 3,
                    backgroundColor: KpColors.success.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(KpColors.success),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded,
                    size: 15, color: KpColors.success),
              ),
            ),
          if (onNow != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onNow,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Now',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.success,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class KpAmountInput extends StatelessWidget {
  const KpAmountInput({
    super.key,
    required this.amount,
    this.currency = 'FCFA',
    this.onEdit,
  });

  final String amount;
  final String currency;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: KpColors.surface,
          borderRadius: BorderRadius.circular(KpRadius.md),
          border: Border.all(color: KpColors.line),
        ),
        child: Row(
          children: [
            Text(
              amount,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                currency,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                    ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 17, color: KpColors.muted),
          ],
        ),
      ),
    );
  }
}

class KpStepDots extends StatelessWidget {
  const KpStepDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: i == active ? 18 : 6,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: i <= active ? KpColors.primary : KpColors.line,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class KpActionRow extends StatelessWidget {
  const KpActionRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class KpIconLabel extends StatelessWidget {
  const KpIconLabel(
      {super.key,
      required this.icon,
      required this.label,
      this.color = KpColors.muted});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class KpContactTile extends StatelessWidget {
  const KpContactTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KpRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: danger ? KpColors.dangerSoft : KpColors.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: danger ? KpColors.danger : KpColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.muted,
                            fontSize: 9.5,
                          ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: KpColors.muted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class KpInfoPanel extends StatelessWidget {
  const KpInfoPanel({
    super.key,
    required this.title,
    required this.child,
    this.tone = KpTipTone.info,
    this.icon,
    this.action,
  });

  final String title;
  final Widget child;
  final KpTipTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      KpTipTone.info => (KpColors.infoSoft, KpColors.info),
      KpTipTone.success => (KpColors.successSoft, KpColors.success),
      KpTipTone.warning => (KpColors.warningSoft, KpColors.warning),
      KpTipTone.danger => (KpColors.dangerSoft, KpColors.danger),
      KpTipTone.gold => (KpColors.goldSoft, KpColors.goldDeep),
    };

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KpRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.ink2,
                  fontSize: 10,
                  height: 1.55,
                ),
            child: child,
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}
