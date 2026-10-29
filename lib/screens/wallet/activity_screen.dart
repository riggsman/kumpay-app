import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../features/money/live_money.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';

/// 29 — Transaction history.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final items = switch (_filter) {
      1 => demoTransactions.where((t) => t.incoming).toList(),
      2 => demoTransactions.where((t) => !t.incoming).toList(),
      _ => demoTransactions,
    };

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      header: KpSimpleHeader(
        title: 'Transactions',
        onBack: () => Navigator.of(context).maybePop(),
        trailing: KpIconButton(
          icon: Icons.tune_rounded,
          size: 36,
          onTap: () => _showFilters(context),
        ),
      ),
      children: [
        KpSegmentedTabs(
          tabs: const ['All', 'Money in', 'Money out'],
          index: _filter,
          onChanged: (i) => setState(() => _filter = i),
        ),
        const SizedBox(height: 14),
        if (AuthScope.maybeRead(context)?.sessionToken != null) ...[
          LiveActivityList(limit: 50, filter: _filter),
        ] else ...[
        const Row(
          children: [
            _Summary(
              label: 'Money in',
              value: '+50 000',
              color: KpColors.success,
              icon: Icons.south_west_rounded,
            ),
            SizedBox(width: 8),
            _Summary(
              label: 'Money out',
              value: '-192 500',
              color: KpColors.danger,
              icon: Icons.north_east_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Today',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: KpColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 2),
        for (var i = 0; i < items.length && i < 1; i++)
          KpActivityTile(
            title: items[i].title,
            subtitle: items[i].subtitle,
            amount: items[i].amount,
            currency: items[i].currency,
            incoming: items[i].incoming,
            icon: items[i].icon,
            showDivider: false,
          ),
        const SizedBox(height: 10),
        Text(
          'Earlier',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: KpColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 2),
        for (var i = 1; i < items.length; i++)
          KpActivityTile(
            title: items[i].title,
            subtitle: items[i].subtitle,
            amount: items[i].amount,
            currency: items[i].currency,
            incoming: items[i].incoming,
            icon: items[i].icon,
            showDivider: i < items.length - 1,
          ),
        if (items.isEmpty) ...[
          const SizedBox(height: 30),
          const Center(
              child: KpStateIcon(type: KpStateIconType.info, size: 72)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No transactions in this filter yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 10.5,
                  ),
            ),
          ),
        ],
        ],
        const SizedBox(height: 14),
        KpButton(
          label: 'Download statement',
          style: KpButtonStyle.outline,
          icon: Icons.download_outlined,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AuthScope.maybeRead(context)?.sessionToken != null
                    ? 'Statements are not available yet.'
                    : 'Statement for May 2026 is being prepared.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: KpColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              const KpDetailCard(
                rows: [
                  KpDetailRow('Period', 'Last 30 days'),
                  KpDetailRow('Wallet', 'All wallets'),
                  KpDetailRow('Type', 'All types'),
                ],
              ),
              const SizedBox(height: 14),
              KpButton(
                label: 'Apply filters',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KpColors.surface,
          borderRadius: BorderRadius.circular(KpRadius.md),
          border: Border.all(color: KpColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KpColors.muted,
                        fontSize: 8.5,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value FCFA',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
