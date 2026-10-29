import 'package:flutter/material.dart';

import '../screens/bills/bills_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/wallet/wallet_screen.dart';
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
  void go(KpTab tab) {
    if (tab == active) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => tab.screen),
      (route) => route.isFirst,
    );
  }

  return KpBottomNav(
    index: active.index,
    onTap: (i) => go(KpTab.values[i]),
    onSend: () => go(KpTab.send),
  );
}
