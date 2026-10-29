import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../wallet/top_up_screen.dart';

/// 30 — Virtual card.
class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  bool _frozen = false;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      header: KpSimpleHeader(
        title: 'Virtual card',
        onBack: () => Navigator.of(context).maybePop(),
        trailing: KpIconButton(
          icon: Icons.more_horiz_rounded,
          size: 36,
          onTap: () => _showCardSettings(context),
        ),
      ),
      children: [
        _VirtualCard(
          frozen: _frozen,
          revealed: _revealed,
          onReveal: () => setState(() => _revealed = !_revealed),
        ),
        const SizedBox(height: 14),
        KpActionRow(
          children: [
            KpButton(
              label: _frozen ? 'Unfreeze' : 'Freeze',
              style: KpButtonStyle.outline,
              onTap: () => _confirmFreeze(context),
            ),
            KpButton(
              label: 'Add funds',
              style: KpButtonStyle.gold,
              onTap: () => kpOpen(
                context,
                const TopUpScreen(usd: true),
                title: 'Fund card',
                step: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            border: Border.all(color: KpColors.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _Metric(
                      label: 'Card balance',
                      value: '\$120.50',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  Container(width: 1, height: 42, color: KpColors.line),
                  const Expanded(
                    child: _Metric(
                      label: 'Monthly limit',
                      value: '\$1,000',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Spent this month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 9.5,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '\$289.99 of \$1,000',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KpColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  value: 0.29,
                  minHeight: 6,
                  backgroundColor: KpColors.soft,
                  valueColor: AlwaysStoppedAnimation<Color>(KpColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const KpSectionHeader(title: 'Card transactions'),
        const SizedBox(height: 2),
        for (var i = 0; i < 3; i++)
          KpActivityTile(
            title: demoTransactions[i == 0 ? 2 : i + 2].title,
            subtitle: demoTransactions[i == 0 ? 2 : i + 2].subtitle,
            amount: demoTransactions[i == 0 ? 2 : i + 2].amount,
            currency: demoTransactions[i == 0 ? 2 : i + 2].currency,
            incoming: false,
            icon: demoTransactions[i == 0 ? 2 : i + 2].icon,
            showDivider: i < 2,
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KpColors.softGreen,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            border: Border.all(color: KpColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_card_rounded,
                      size: 19, color: KpColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add an XAF card',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                  ),
                  const Spacer(),
                  const KpPill(label: '600 FCFA', tone: KpPillTone.gold),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'One card per currency. Your free creation has been used.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.ink2,
                      fontSize: 9.5,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 10),
              KpButton(
                label: 'Create XAF card',
                style: KpButtonStyle.outline,
                onTap: () => _showCreateSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Card name is set to your verified legal name. Contact support if your name has changed.',
          ),
        ),
      ],
    );
  }

  void _confirmFreeze(BuildContext context) {
    final freezing = !_frozen;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: KpStateIcon(
                  type:
                      freezing ? KpStateIconType.lock : KpStateIconType.success,
                  size: 62,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                freezing ? 'Freeze this card?' : 'Unfreeze this card?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                freezing
                    ? 'New payments on this card will be declined until you unfreeze it. You can turn it back on at any time.'
                    : 'Payments on this card will be accepted again as soon as you unfreeze it.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              KpButton(
                label: freezing ? 'Freeze card' : 'Unfreeze card',
                style: freezing ? KpButtonStyle.danger : KpButtonStyle.primary,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _frozen = freezing);
                },
              ),
              const SizedBox(height: 4),
              KpTextLink(
                'Cancel',
                color: KpColors.muted,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCardSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Card settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              KpSettingsTile(
                title: 'View card details',
                icon: Icons.visibility_outlined,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _revealed = true);
                },
              ),
              KpSettingsTile(
                title: 'Spending limits',
                icon: Icons.speed_rounded,
                trailingText: '\$1,000 / mo',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              KpSettingsTile(
                title: 'Billing address',
                icon: Icons.location_on_outlined,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              KpSettingsTile(
                title: 'Report lost card',
                icon: Icons.report_gmailerrorred_rounded,
                danger: true,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                  child: KpStateIcon(type: KpStateIconType.lock, size: 62)),
              const SizedBox(height: 14),
              Text(
                'Create XAF card?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                'A creation fee of 600 FCFA will be charged from your FCFA wallet. The card will carry your verified name.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              KpButton(
                label: 'Confirm · pay 600 FCFA',
                style: KpButtonStyle.gold,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('XAF card created.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: KpColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              KpTextLink(
                'Cancel',
                color: KpColors.muted,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VirtualCard extends StatelessWidget {
  const _VirtualCard({
    required this.frozen,
    required this.revealed,
    required this.onReveal,
  });

  final bool frozen;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: frozen
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6E7D75), Color(0xFF4C5A52)],
              )
            : KpColors.gradientForest,
        borderRadius: BorderRadius.circular(KpRadius.xl),
        boxShadow: KpShadows.balance,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KpColors.gold.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: KpColors.gradientGold,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'K',
                      style: TextStyle(
                        color: KpColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'KumPay',
                    style: TextStyle(
                      color: Color(0xFFFDF9EE),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  const KpPill(label: 'USD', tone: KpPillTone.gold),
                  if (frozen) ...[
                    const SizedBox(width: 5),
                    const KpPill(label: 'Frozen', tone: KpPillTone.red),
                  ],
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Icon(
                    Icons.contactless_rounded,
                    color: Color(0xFFDCCE9D),
                    size: 22,
                  ),
                  const Spacer(),
                  Text(
                    raised,
                    style: TextStyle(
                      color: const Color(0xFFFDF9EE).withValues(alpha: 0.7),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                revealed ? '4821 9034 1120 4821' : '••••  ••••  ••••  4821',
                style: const TextStyle(
                  color: Color(0xFFFDF9EE),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color:
                                const Color(0xFFFDF9EE).withValues(alpha: 0.45),
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          demoUser.name.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFDF9EE),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EXPIRES',
                        style: TextStyle(
                          color:
                              const Color(0xFFFDF9EE).withValues(alpha: 0.45),
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '09 / 29',
                        style: TextStyle(
                          color: Color(0xFFFDF9EE),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 38,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF9EE),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'VISA',
                      style: TextStyle(
                        color: Color(0xFF1A1F71),
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: onReveal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      revealed
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 13,
                      color: const Color(0xFFDCCE9D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      revealed ? 'Hide details' : 'Show details',
                      style: const TextStyle(
                        color: Color(0xFFDCCE9D),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const raised = 'VIRTUAL';
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: KpColors.muted),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}
