import 'package:flutter/material.dart';

import '../features/feature_flags/app_feature.dart';
import '../screens/bills/bills_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../state/feature_flags_scope.dart';
import 'kp_bottom_nav.dart';

/// Bottom-navigation destinations, in the order shown by [KpBottomNav].
enum KpTab {
  home,
  wallet,
  send,
  pay,
  profile;

  Widget get screen => switch (this) {
    KpTab.home => const HomeScreen(),
    KpTab.wallet => const WalletScreen(),
    KpTab.send => const TransferScreen(),
    KpTab.pay => const BillsScreen(),
    KpTab.profile => const ProfileScreen(),
  };
}

/// The bottom navigation shown on every signed-in screen.
///
/// [active] is the tab the screen belongs to and is highlighted. Switching to
/// another tab replaces everything above the root route, so the back stack
/// never grows from tab taps.
KpBottomNav kpAppNav(BuildContext context, {required KpTab active}) {
  final showSend = FeatureFlagsScope.enabled(context, AppFeature.send);
  final showBills = FeatureFlagsScope.enabled(context, AppFeature.bills);
  final destinations = <KpTab>[
    KpTab.home,
    KpTab.wallet,
    if (showSend) KpTab.send,
    if (showBills) KpTab.pay,
    KpTab.profile,
  ];

  void go(KpTab tab) {
    if (tab == active) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => tab.screen),
      (route) => route.isFirst,
    );
  }

  final activeIndex = destinations.indexOf(active);
  if (activeIndex < 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  return KpBottomNav(
    index: activeIndex < 0 ? 0 : activeIndex,
    onTap: (i) => go(destinations[i]),
    items: [
      for (final tab in destinations)
        KpNavItem(
          icon: switch (tab) {
            KpTab.home => Icons.home_rounded,
            KpTab.wallet => Icons.account_balance_wallet_outlined,
            KpTab.send => Icons.send_rounded,
            KpTab.pay => Icons.receipt_long_outlined,
            KpTab.profile => Icons.person_outline_rounded,
          },
          label: switch (tab) {
            KpTab.home => 'Home',
            KpTab.wallet => 'Wallet',
            KpTab.send => 'Send',
            KpTab.pay => 'Pay',
            KpTab.profile => 'Profile',
          },
          center: tab == KpTab.send,
        ),
    ],
  );
}
