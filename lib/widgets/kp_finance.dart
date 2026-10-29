import 'package:flutter/material.dart';

import '../data/demo.dart';
import '../theme/kp_theme.dart';
import 'kp_controls.dart';

class KpBalanceCard extends StatefulWidget {
  const KpBalanceCard({
    super.key,
    required this.amount,
    this.label = 'Available balance',
    this.account = 'Acct ••• 3391',
    this.wallet = 'KumPay Wallet',
    this.primaryAction = 'Add money',
    this.secondaryAction = 'Send',
    this.showPrimary = true,
    this.showSecondary = true,
    this.onPrimary,
    this.onSecondary,
  });

  final String amount;
  final String label;
  final String account;
  final String wallet;
  final String primaryAction;
  final String secondaryAction;
  final bool showPrimary;
  final bool showSecondary;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  State<KpBalanceCard> createState() => _KpBalanceCardState();
}

class _KpBalanceCardState extends State<KpBalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 17),
      decoration: BoxDecoration(
        gradient: KpColors.gradientForest,
        borderRadius: BorderRadius.circular(KpRadius.xl),
        boxShadow: KpShadows.balance,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    KpColors.gold.withValues(alpha: 0.28),
                    KpColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFC7D8CE),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(KpRadius.pill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 10,
                          color: Color(0xFFE9C66A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SECURED',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFFE9C66A),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _hidden ? '••• ••• FCFA' : widget.amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFFFDF9EE),
                            fontWeight: FontWeight.w800,
                            fontSize: 27,
                            letterSpacing: -0.8,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _hidden = !_hidden),
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                        color: const Color(0xFFC7D8CE),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.account,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFDCE7E1),
                          fontSize: 8.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.wallet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFA9BDB3),
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.showPrimary || widget.showSecondary) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.showPrimary)
                      Expanded(
                        child: _BalanceAction(
                          label: widget.primaryAction,
                          icon: Icons.add_rounded,
                          gold: true,
                          onTap: widget.onPrimary,
                        ),
                      ),
                    if (widget.showPrimary && widget.showSecondary)
                      const SizedBox(width: 9),
                    if (widget.showSecondary)
                      Expanded(
                        child: _BalanceAction(
                          label: widget.secondaryAction,
                          icon: Icons.north_east_rounded,
                          gold: false,
                          onTap: widget.onSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceAction extends StatelessWidget {
  const _BalanceAction({
    required this.label,
    required this.icon,
    required this.gold,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool gold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: gold ? KpColors.gold : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: gold ? KpColors.primaryDark : const Color(0xFFFDF9EE),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: gold ? KpColors.primaryDark : const Color(0xFFFDF9EE),
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KpKycBanner extends StatelessWidget {
  const KpKycBanner({
    super.key,
    required this.verified,
    this.onTap,
    this.subtitle,
  });

  final bool verified;
  final VoidCallback? onTap;

  /// Replaces the sample tier line when the signed-in account has a real status.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bg = verified ? KpColors.successSoft : KpColors.goldSoft;
    final fg = verified ? KpColors.success : KpColors.goldDeep;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KpRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  verified
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  size: 16,
                  color: fg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verified ? 'KYC verified' : 'Complete your KYC',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle ??
                          (verified
                              ? 'Tier 2 · Daily limit 2,000,000 FCFA'
                              : 'Tier 0 · Upgrade to unlock higher limits'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: verified ? KpColors.ink2 : KpColors.ink2,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              KpPill(
                label: verified ? 'Active' : 'Pending',
                tone: verified ? KpPillTone.green : KpPillTone.gold,
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 17, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class KpMiniAccountTile extends StatelessWidget {
  const KpMiniAccountTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.tone = KpServiceTone.green,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final KpServiceTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      KpServiceTone.green => (KpColors.softGreen, KpColors.primary),
      KpServiceTone.gold => (KpColors.goldSoft, KpColors.goldDeep),
      KpServiceTone.rose => (KpColors.dangerSoft, KpColors.danger),
      KpServiceTone.info => (KpColors.infoSoft, KpColors.info),
      KpServiceTone.neutral => (KpColors.soft, KpColors.ink2),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KpColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: KpColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class KpBillerChip extends StatelessWidget {
  const KpBillerChip({super.key, required this.bill, this.onTap});

  final KpBill bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KpRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
            boxShadow: KpShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KpColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(bill.icon, size: 20, color: KpColors.goldDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      bill.category,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KpColors.muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.unfold_more_rounded,
                size: 17,
                color: KpColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KpSegmentedTabs extends StatelessWidget {
  const KpSegmentedTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KpColors.soft,
        borderRadius: BorderRadius.circular(KpRadius.md),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? KpColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: i == index ? KpShadows.soft : null,
                  ),
                  child: Text(
                    tabs[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: i == index ? KpColors.ink : KpColors.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
