import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_config.dart';
import '../../data/contacts/contacts_repository.dart';
import '../../data/kyc/kyc_repository.dart';
import '../../data/notifications/notifications_repository.dart';
import '../../data/pin/pin_repository.dart';
import '../../data/refunds/refunds_repository.dart';
import '../../data/support/support_repository.dart';
import '../../features/feature_flags/app_feature.dart';
import '../../features/kyc/kyc_page.dart';
import '../../features/transactions/account_limits.dart';
import '../../state/feature_flags_scope.dart';
import '../../features/pin/pin_page.dart';
import '../../features/refunds/refunds_page.dart';
import '../../features/money/live_money.dart';
import '../../features/support/support_page.dart';
import '../../data/demo.dart';
import '../../features/contacts/contacts_page.dart';
import '../../preview/preview_page.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_finance.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../auth/account_entry_screen.dart';
import '../auth/change_phone_screen.dart';
import '../auth/help_screens.dart';
import '../kyc/kyc_screens.dart';
import '../wallet/activity_screen.dart';
import '../wallet/devices_page.dart';
import '../wallet/wallet_screen.dart';
import 'change_pin_screen.dart';
import 'language_screen.dart';

/// 31 — Profile, settings and sign-out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _biometrics = true;
  bool _mfa = false;
  bool _pushNotifications = true;
  String? _niu;
  bool _niuLoaded = false;
  int? _phoneCount;
  AccountLimits? _limits;

  @override
  void initState() {
    super.initState();
    languageChoice.addListener(_onLanguage);
    WidgetsBinding.instance.addObserver(this);
    final repo = moneyRepo(context);
    if (repo == null) return;
    repo.wallet().then((wallet) {
      if (!mounted) return;
      setState(() {
        _niu = wallet.niu;
        _niuLoaded = true;
        _phoneCount = wallet.phones.length;
      });
    }).catchError((Object _) {});
    _loadLimits();
    repo.security().then((prefs) {
      if (!mounted || prefs == null) return;
      setState(() {
        _biometrics = prefs.biometrics;
        _mfa = prefs.mfa;
      });
    }).catchError((Object _) {});
  }

  void _showLimits() {
    final limits = _limits;
    if (limits == null) {
      _openKyc(context);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Your limits'),
        content: Text(limits.summary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSecurity({bool? biometrics, bool? mfa}) async {
    final previousBiometrics = _biometrics;
    final previousMfa = _mfa;
    setState(() {
      if (biometrics != null) _biometrics = biometrics;
      if (mfa != null) _mfa = mfa;
    });
    final repo = moneyRepo(context);
    if (repo == null) return;
    try {
      await repo.updateSecurity(biometrics: _biometrics, mfa: _mfa);
    } on ApiException catch (error) {
      if (error.status == 404 || !mounted) return;
      setState(() {
        _biometrics = previousBiometrics;
        _mfa = previousMfa;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: KpColors.primary,
        ),
      );
    }
  }

  void _onLanguage() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    languageChoice.removeListener(_onLanguage);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadLimits();
  }

  void _loadLimits() {
    final repo = moneyRepo(context);
    if (repo == null) return;
    repo.limits().then((limits) {
      if (!mounted || limits == null) return;
      setState(() => _limits = limits);
    }).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthScope.maybeOf(context)?.user;
    final displayName = signedIn?.name ?? demoUser.name;
    final displayPhone = signedIn?.phone ?? demoUser.phone;
    return KpPage(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
      header: KpSimpleHeader(
        title: 'Profile',
        onBack: () => Navigator.of(context).maybePop(),
        trailing: KpIconButton(
          icon: Icons.edit_outlined,
          size: 36,
          onTap: () => _showEditSheet(context),
        ),
      ),
      bottomNav: kpAppNav(context, active: KpTab.profile),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: KpColors.gradientForest,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            boxShadow: KpShadows.balance,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: KpColors.gradientGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Text(
                  _initials(displayName),
                  style: const TextStyle(
                    color: KpColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFFDF9EE),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      displayPhone,
                      style: TextStyle(
                        color: const Color(0xFFFDF9EE).withValues(alpha: 0.65),
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: KpColors.gold,
                        borderRadius: BorderRadius.circular(KpRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            signedIn == null || signedIn.kyc == 'approved'
                                ? Icons.verified_rounded
                                : Icons.pending_rounded,
                            size: 10,
                            color: KpColors.primaryDark,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            signedIn == null
                                ? 'KYC VERIFIED'
                                : _kycBadge(signedIn.kyc),
                            style: const TextStyle(
                              color: KpColors.primaryDark,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MEMBER SINCE',
                    style: TextStyle(
                      color: const Color(0xFFFDF9EE).withValues(alpha: 0.45),
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    signedIn == null
                        ? 'Mar 2026'
                        : _memberSince(signedIn.createdAt),
                    style: const TextStyle(
                      color: Color(0xFFFDF9EE),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  label: 'Tier',
                  value: signedIn == null ? 'Tier 2' : _kycLabel(signedIn.kyc),
                  onTap: () => _openKyc(context),
                ),
              ),
              Container(width: 1, height: 30, color: KpColors.line),
              Expanded(
                child: _ProfileStat(
                  label: 'Limits',
                  value:
                      signedIn == null ? '2M FCFA' : (_limits?.compact ?? '—'),
                  onTap: () => _showLimits(),
                ),
              ),
              Container(width: 1, height: 30, color: KpColors.line),
              Expanded(
                child: _ProfileStat(
                  label: 'NIU',
                  value: signedIn == null
                      ? '•• 4821'
                      : (_niuLoaded ? (_niu ?? 'Not issued') : '…'),
                  onTap: () => _openKyc(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const KpSectionHeader(title: 'Account'),
        KpSettingsTile(
          title: 'Personal details',
          icon: Icons.person_outline_rounded,
          onTap: () => _showEditSheet(context),
        ),
        KpSettingsTile(
          title: 'Phone & email',
          icon: Icons.contact_phone_outlined,
          onTap: () {
            final token = AuthScope.maybeRead(context)?.sessionToken;
            if (token != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ContactsPage(
                    repository: ContactsRepository(
                      baseUrl: kApiBase,
                      token: token,
                    ),
                  ),
                ),
              );
              return;
            }
            kpOpen(
              context,
              const ChangePhoneScreen(),
              title: 'Change phone number',
              step: 2,
            );
          },
        ),
        KpSettingsTile(
          title: 'KYC & limits',
          icon: Icons.verified_user_outlined,
          trailingText: signedIn == null ? 'Verified' : _kycLabel(signedIn.kyc),
          onTap: () => _openKyc(context),
        ),
        KpSettingsTile(
          title: 'Refunds',
          icon: Icons.replay_rounded,
          onTap: () {
            final token = AuthScope.maybeRead(context)?.sessionToken;
            if (token != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RefundsPage(
                    repository: RefundsRepository(
                      baseUrl: kApiBase,
                      token: token,
                    ),
                  ),
                ),
              );
              return;
            }
            kpOpen(context, const ActivityScreen(), title: 'Activity', step: 0);
          },
        ),
        KpSettingsTile(
          title: 'Linked accounts',
          icon: Icons.account_balance_outlined,
          trailingText:
              signedIn == null ? '3' : (_phoneCount?.toString() ?? '…'),
          onTap: () =>
              kpOpen(context, const WalletScreen(), title: 'Wallet', step: 24),
        ),
        const SizedBox(height: 8),
        const KpSectionHeader(title: 'Security'),
        KpSettingsTile(
          title: 'Change PIN',
          icon: Icons.pin_outlined,
          onTap: () {
            final token = AuthScope.maybeRead(context)?.sessionToken;
            if (token != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PinPage(
                    repository: PinRepository(baseUrl: kApiBase, token: token),
                  ),
                ),
              );
              return;
            }
            kpOpen(
              context,
              const ChangePinScreen(),
              title: 'Change PIN',
              note: 'Current PIN → OTP → new PIN',
            );
          },
        ),
        if (FeatureFlagsScope.enabled(context, AppFeature.biometrics))
          KpToggleRow(
            title: 'Biometric login',
            subtitle: signedIn == null
                ? 'Use Face ID or fingerprint'
                : 'Confirm sign-in on this phone',
            icon: Icons.fingerprint_rounded,
            value: _biometrics,
            onChanged: (value) => _saveSecurity(biometrics: value),
          ),
        if (FeatureFlagsScope.enabled(context, AppFeature.mfa))
          KpToggleRow(
            title: 'Extra sign-in check',
            subtitle: 'Ask for a code on payments and sign-in',
            icon: Icons.shield_outlined,
            value: _mfa,
            onChanged: (value) => _saveSecurity(mfa: value),
          ),
        KpSettingsTile(
          title: 'Devices & sessions',
          icon: Icons.devices_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DevicesPage(repository: moneyRepo(context)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const KpSectionHeader(title: 'Preferences'),
        KpSettingsTile(
          title: 'Language',
          icon: Icons.language_rounded,
          trailingText: _languageName(languageChoice.value),
          onTap: () => kpOpen(
            context,
            const LanguageScreen(),
            title: 'Language',
            step: 0,
          ),
        ),
        KpToggleRow(
          title: 'Push notifications',
          subtitle: 'Payments, security and offers',
          icon: Icons.notifications_none_rounded,
          value: _pushNotifications,
          onChanged: (v) => setState(() => _pushNotifications = v),
        ),
        KpSettingsTile(
          title: 'Help & support',
          icon: Icons.support_agent_rounded,
          onTap: () {
            final token = AuthScope.maybeRead(context)?.sessionToken;
            if (token != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SupportPage(
                    repository: SupportRepository(
                      baseUrl: kApiBase,
                      token: token,
                    ),
                  ),
                ),
              );
              return;
            }
            kpOpen(
              context,
              const HelpScreen(),
              title: 'Contact support',
              step: 14,
            );
          },
        ),
        const SizedBox(height: 14),
        KpButton(
          label: 'Log out',
          style: KpButtonStyle.outline,
          icon: Icons.logout_rounded,
          onTap: () => _showLogoutSheet(context),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'KumPay v1.0.0 · Made in Cameroon',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: KpColors.muted, fontSize: 8.5),
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context) {
    final user = AuthScope.maybeOf(context)?.user;
    final token = AuthScope.maybeRead(context)?.sessionToken;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final signedIn = user != null && token != null && token.isNotEmpty;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            4,
            22,
            22 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personal details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              if (signedIn) ...[
                KpDetailCard(
                  rows: [
                    KpDetailRow('Full name', user.name),
                    KpDetailRow('Phone number', user.phone ?? 'Not set'),
                    KpDetailRow('Email', user.email ?? 'Not added'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Phone and email changes use a one-time code. The account name is set at registration.',
                ),
                const SizedBox(height: 16),
                KpButton(
                  label: 'Phone & email',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ContactsPage(
                          repository: ContactsRepository(
                            baseUrl: kApiBase,
                            token: token,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                const KpTextField(label: 'Full name', hint: 'Aïcha Ngono'),
                const SizedBox(height: 12),
                const KpTextField(
                  label: 'Phone number',
                  hint: '+237 677 12 34 56',
                ),
                const SizedBox(height: 12),
                const KpTextField(label: 'Email', hint: 'aicha@mail.cm'),
                const SizedBox(height: 16),
                KpButton(
                  label: 'Save changes',
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showLogoutSheet(BuildContext context) {
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
                child: KpStateIcon(type: KpStateIconType.lock, size: 60),
              ),
              const SizedBox(height: 12),
              Text(
                'Log out of KumPay?',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'You’ll need your phone number and a one-time code to sign back in.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: KpColors.muted, fontSize: 10.5),
              ),
              const SizedBox(height: 16),
              KpButton(
                label: 'Log out',
                style: KpButtonStyle.danger,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final auth = AuthScope.maybeRead(context);
                  if (auth != null && auth.isSignedIn) {
                    await auth.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    return;
                  }
                  kpOpen(
                    context,
                    const AccountEntryScreen(),
                    title: 'Login',
                    step: 1,
                  );
                },
              ),
              const SizedBox(height: 4),
              KpTextLink(
                'Stay signed in',
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: KpColors.muted, fontSize: 8),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
          ),
        ],
      ),
    );
  }
}

/// Notifications inbox (client).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _InboxItem {
  const _InboxItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.background,
    required this.unread,
    required this.kind,
    this.id,
  });

  final String? id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final Color background;
  final bool unread;
  final String kind;

  _InboxItem copyWith({bool? unread}) {
    return _InboxItem(
      id: id,
      title: title,
      body: body,
      time: time,
      icon: icon,
      color: color,
      background: background,
      unread: unread ?? this.unread,
      kind: kind,
    );
  }
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;
  bool _readAll = false;
  String? _token;
  bool _loading = false;
  String? _error;
  List<_InboxItem>? _live;

  static const _demo = [
    _InboxItem(
      title: 'Payment received',
      body: 'You received 50 000 FCFA from MTN MoMo top-up.',
      time: 'Today · 09:14',
      icon: Icons.south_west_rounded,
      color: KpColors.success,
      background: KpColors.successSoft,
      unread: true,
      kind: 'payment',
    ),
    _InboxItem(
      title: 'Card transaction',
      body: 'Netflix.com charged \$9.99 on your USD card •4821.',
      time: '20 Oct · 07:45',
      icon: Icons.credit_card_rounded,
      color: KpColors.goldDeep,
      background: KpColors.goldSoft,
      unread: true,
      kind: 'payment',
    ),
    _InboxItem(
      title: 'New device sign-in',
      body: 'iPhone 15 Pro signed in from Douala, Cameroon.',
      time: '18 Oct · 21:02',
      icon: Icons.phone_iphone_rounded,
      color: KpColors.info,
      background: KpColors.infoSoft,
      unread: false,
      kind: 'security',
    ),
    _InboxItem(
      title: 'KYC approved',
      body: 'Your identity is verified. Your NIU is CM-2026-004821.',
      time: '16 Oct · 11:20',
      icon: Icons.verified_user_outlined,
      color: KpColors.success,
      background: KpColors.successSoft,
      unread: false,
      kind: 'kyc',
    ),
  ];

  bool get _signedIn => _token != null;

  List<_InboxItem> get _source => _signedIn ? (_live ?? const []) : _demo;

  @override
  void initState() {
    super.initState();
    final token = AuthScope.maybeRead(context)?.sessionToken;
    if (token != null && token.isNotEmpty) {
      _token = token;
      _loading = true;
      _load();
    }
  }

  NotificationsRepository get _repo =>
      NotificationsRepository(baseUrl: kApiBase, token: _token!);

  Future<void> _load() async {
    try {
      final inbox = await _repo.list();
      if (!mounted) return;
      setState(() {
        _live = [for (final item in inbox.items) _fromNotice(item)];
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't load notifications.";
        _loading = false;
      });
    }
  }

  Future<void> _markAll() async {
    if (!_signedIn) {
      setState(() => _readAll = true);
      return;
    }
    try {
      await _repo.markAllRead();
      if (!mounted) return;
      setState(() {
        _live = [for (final item in _source) item.copyWith(unread: false)];
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't mark notifications read.";
      });
    }
  }

  Future<void> _open(_InboxItem item) async {
    var shown = item;
    if (_signedIn && item.id != null) {
      try {
        shown = _fromNotice(await _repo.open(item.id!));
        if (!mounted) return;
        setState(() {
          _live = [
            for (final current in _source)
              if (current.id == item.id) shown else current,
          ];
          _error = null;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _error = error is ApiException
              ? error.message
              : "Couldn't open that notification.";
        });
        return;
      }
    }
    if (!mounted) return;
    _showDetail(shown);
  }

  @override
  Widget build(BuildContext context) {
    final items = switch (_tab) {
      1 => _source.where((item) => item.kind == 'payment').toList(),
      2 => _source
          .where((item) => item.kind == 'security' || item.kind == 'kyc')
          .toList(),
      _ => _source,
    };
    final unread = _signedIn
        ? _source.where((item) => item.unread).length
        : (_readAll ? 0 : _demo.where((item) => item.unread).length);

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: KpSimpleHeader(
        title: 'Notifications',
        onBack: () => Navigator.of(context).maybePop(),
        trailing: KpIconButton(
          icon: Icons.done_all_rounded,
          size: 36,
          onTap: _markAll,
        ),
      ),
      children: [
        KpPill(
          label: unread == 0 ? 'All caught up' : '$unread unread',
          tone: unread == 0 ? KpPillTone.neutral : KpPillTone.gold,
        ),
        const SizedBox(height: 10),
        KpSegmentedTabs(
          tabs: const ['All', 'Payments', 'Security'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Loading your alerts…'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KpTip(tone: KpTipTone.danger, child: Text(_error!)),
          ),
        if (!_loading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No alerts in this tab yet.'),
          ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NotificationTile(
              title: item.title,
              body: item.body,
              time: item.time,
              icon: item.icon,
              color: item.color,
              background: item.background,
              unread: item.unread && (_signedIn || !_readAll),
              onTap: () => _open(item),
            ),
          ),
        const SizedBox(height: 8),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Security alerts are always sent to your primary phone, even if push notifications are off.',
          ),
        ),
      ],
    );
  }

  void _showDetail(_InboxItem item) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, size: 19, color: item.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KpColors.ink2,
                      fontSize: 11.5,
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                item.time,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: KpColors.muted, fontSize: 9),
              ),
              const SizedBox(height: 16),
              const KpTip(
                tone: KpTipTone.info,
                child: Text(
                  'This is a read-only alert. If something looks wrong, contact support immediately.',
                ),
              ),
              const SizedBox(height: 14),
              KpButton(
                label: 'Close',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

_InboxItem _fromNotice(ClientNotice notice) {
  final style = switch (notice.kind) {
    'payment' => (
        Icons.south_west_rounded,
        KpColors.success,
        KpColors.successSoft,
      ),
    'security' => (
        Icons.phone_iphone_rounded,
        KpColors.info,
        KpColors.infoSoft,
      ),
    'kyc' => (
        Icons.verified_user_outlined,
        KpColors.success,
        KpColors.successSoft,
      ),
    'support' => (
        Icons.support_agent_rounded,
        KpColors.goldDeep,
        KpColors.goldSoft,
      ),
    _ => (
        Icons.notifications_none_rounded,
        KpColors.goldDeep,
        KpColors.goldSoft,
      ),
  };
  return _InboxItem(
    id: notice.id,
    title: notice.title,
    body: notice.body,
    time: _noticeTime(notice.createdAt),
    icon: style.$1,
    color: style.$2,
    background: style.$3,
    unread: !notice.read,
    kind: notice.kind,
  );
}

String _noticeTime(String? iso) {
  final parsed = DateTime.tryParse(iso ?? '');
  if (parsed == null) return '';
  final local = parsed.toLocal();
  final now = DateTime.now();
  final sameDay = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = sameDay ? 'Today' : '${local.day} ${months[local.month - 1]}';
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day · $hour:$minute';
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.background,
    required this.unread,
    required this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final Color background;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KpRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(
              color:
                  unread ? KpColors.gold.withValues(alpha: 0.5) : KpColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: KpColors.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: KpColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink2,
                            fontSize: 9.5,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: KpColors.muted, fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openKyc(BuildContext context) {
  final token = AuthScope.maybeRead(context)?.sessionToken;
  if (token != null) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KycPage(
          repository: KycRepository(baseUrl: kApiBase, token: token),
        ),
      ),
    );
    return;
  }
  kpOpen(context, const KycApprovedScreen(), title: 'KYC & limits', step: 0);
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'KP';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _kycBadge(String kyc) {
  return switch (kyc) {
    'approved' => 'KYC VERIFIED',
    'pending' || 'in_progress' => 'KYC PENDING',
    'rejected' => 'KYC REJECTED',
    _ => 'KYC NEEDED',
  };
}

String _memberSince(DateTime? createdAt) {
  if (createdAt == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = createdAt.toLocal();
  return '${months[local.month - 1]} ${local.year}';
}

String _languageName(String code) {
  for (final language in demoLanguages) {
    if (language.code == code) return language.name;
  }
  return 'English';
}

String _kycLabel(String kyc) {
  return switch (kyc) {
    'approved' => 'Approved',
    'pending' => 'Waiting',
    'in_progress' => 'In review',
    'rejected' => 'Rejected',
    _ => 'Not started',
  };
}
