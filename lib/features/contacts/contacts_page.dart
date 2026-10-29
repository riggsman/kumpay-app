import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_config.dart';
import '../../core/phone.dart';
import '../../data/contacts/contacts_repository.dart';
import '../../data/support/support_repository.dart';
import '../support/support_page.dart';
import '../../features/auth/auth_messages.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Phone, top-up number and email, backed by `/api/me` contacts.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.repository});

  final ContactsRepository repository;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  ContactBook? _book;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = await widget.repository.load();
      if (!mounted) return;
      AuthScope.read(context).applyContacts(
        phone: book.primaryPhone.number,
        email: book.email.address,
      );
      setState(() => _book = book);
    } catch (error) {
      if (mounted) setState(() => _error = contactErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChange(Widget page) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => page),
    );
    if (changed == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return KpPage(
      header: KpSimpleHeader(
        title: 'Phone & email',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
        if (book != null) ...[
          const SizedBox(height: 12),
          _Block(
            title: 'Primary number',
            subtitle: 'Used to sign in and to receive every security message.',
            value: _formatPhone(book.primaryPhone.number),
            badge: book.primaryPhone.verified ? 'Verified' : 'Unverified',
            action: 'Change number',
            onAction: () => _openChange(
              _PhoneEditor(
                repository: widget.repository,
                title: 'Change phone number',
                body: book.primaryPhone.canChange
                    ? 'We will send a code to the new number. Your old number is told about the change.'
                    : 'You can change this number again on ${book.primaryPhone.nextEligibleAt ?? 'a later date'}.',
                locked: !book.primaryPhone.canChange,
                remainingDays: book.primaryPhone.remainingDays,
                submit: widget.repository.requestPhoneChange,
                confirm: widget.repository.verifyPhoneChange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Block(
            title: 'Top-up number',
            subtitle: 'Optional. It can fund your wallet and never receives codes.',
            value: book.topupPhone?.number == null
                ? 'Not set'
                : _formatPhone(book.topupPhone!.number),
            badge: book.topupPhone == null
                ? null
                : (book.topupPhone!.verified ? 'Verified' : 'Unverified'),
            action: book.topupPhone == null ? 'Add number' : 'Replace number',
            onAction: () => _openChange(
              _PhoneEditor(
                repository: widget.repository,
                title: 'Top-up number',
                body: 'We will send a code to this number before it can fund your wallet.',
                submit: widget.repository.requestTopupPhone,
                confirm: widget.repository.verifyTopupPhone,
              ),
            ),
            secondary: book.topupPhone == null ? null : 'Remove',
            onSecondary: book.topupPhone == null ? null : _removeTopup,
          ),
          const SizedBox(height: 12),
          _Block(
            title: 'Email',
            subtitle: 'Codes and receipts are sent here only after it is verified.',
            value: book.email.address ?? 'Not set',
            badge: book.email.address == null
                ? null
                : (book.email.verified ? 'Verified' : 'Unverified'),
            action: book.email.address == null ? 'Add email' : 'Change email',
            onAction: () => _openChange(
              _EmailEditor(repository: widget.repository, replacing: book.email.address != null),
            ),
            secondary: book.email.address != null && !book.email.verified ? 'Verify email' : null,
            onSecondary: book.email.address != null && !book.email.verified
                ? () => _openChange(_EmailVerify(repository: widget.repository))
                : null,
          ),
        ],
      ],
    );
  }

  Future<void> _removeTopup() async {
    setState(() => _error = null);
    try {
      final book = await widget.repository.removeTopupPhone();
      if (!mounted) return;
      setState(() => _book = book);
    } catch (error) {
      if (mounted) setState(() => _error = contactErrorMessage(error));
    }
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.action,
    required this.onAction,
    this.badge,
    this.secondary,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String value;
  final String? badge;
  final String action;
  final VoidCallback onAction;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: KpColors.muted, fontSize: 11, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              if (badge != null) KpPill(label: badge!, tone: KpPillTone.green),
            ],
          ),
          const SizedBox(height: 8),
          KpTextLink(action, onTap: onAction),
          if (secondary != null) KpTextLink(secondary!, color: KpColors.danger, onTap: onSecondary),
        ],
      ),
    );
  }
}

class _PhoneEditor extends StatefulWidget {
  const _PhoneEditor({
    required this.repository,
    required this.title,
    required this.body,
    required this.submit,
    required this.confirm,
    this.locked = false,
    this.remainingDays = 0,
  });

  final ContactsRepository repository;
  final String title;
  final String body;
  final bool locked;
  final int remainingDays;
  final Future<OtpTicket> Function(String phone) submit;
  final Future<ContactBook> Function({required String challengeId, required String code}) confirm;

  @override
  State<_PhoneEditor> createState() => _PhoneEditorState();
}

class _PhoneEditorState extends State<_PhoneEditor> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;
  _Lock? _lock;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = Phone.normalize(_phone.text);
    if (phone == null) {
      setState(() => _error = 'Enter a valid Cameroon phone number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await widget.submit(phone);
      if (!mounted) return;
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _CodePage(
            title: widget.title,
            sentTo: Phone.mask(phone),
            confirm: (code) => widget.confirm(challengeId: ticket.challengeId, code: code),
          ),
        ),
      );
      if (done == true && mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final lock = _Lock.from(error);
      setState(() {
        _lock = lock;
        _error = lock == null ? contactErrorMessage(error) : null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked || _lock != null;
    final days = _lock?.remainingDays ?? widget.remainingDays;
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        KpScreenTitle(widget.title, widget.body),
        const SizedBox(height: 16),
        if (locked) ...[
          KpTip(
            tone: KpTipTone.warning,
            child: Text(
              'This number can be changed again in $days days. '
              'Contact ${_lock?.supportEmail ?? 'support@kumpay.cm'} or ${_lock?.supportWhatsApp ?? '+237 690 00 00 00'} if you no longer have it.',
            ),
          ),
          const SizedBox(height: 16),
          KpButton(
            label: 'Contact support',
            onTap: () {
              final token = AuthScope.maybeRead(context)?.sessionToken;
              if (token == null || token.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SupportPage(
                    repository: SupportRepository(baseUrl: kApiBase, token: token),
                  ),
                ),
              );
            },
          ),
        ]
        else ...[
          KpPhoneField(controller: _phone, label: 'New phone number'),
          if (_error != null) ...[
            const SizedBox(height: 10),
            KpInlineError(_error!),
          ],
          const SizedBox(height: 16),
          KpButton(label: 'Send code', busy: _busy, onTap: _busy ? null : _send),
        ],
      ],
    );
  }
}

class _EmailEditor extends StatefulWidget {
  const _EmailEditor({required this.repository, required this.replacing});

  final ContactsRepository repository;
  final bool replacing;

  @override
  State<_EmailEditor> createState() => _EmailEditorState();
}

class _EmailEditorState extends State<_EmailEditor> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final address = _email.text.trim();
    if (!address.contains('@') || !address.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await widget.repository.requestEmailChange(address);
      if (!mounted) return;
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _CodePage(
            title: 'Confirm email',
            sentTo: address,
            confirm: (code) => widget.repository.verifyEmailChange(challengeId: ticket.challengeId, code: code),
          ),
        ),
      );
      if (done == true && mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = contactErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        KpScreenTitle(
          widget.replacing ? 'Change email' : 'Add email',
          'A code is sent to the new address. It stays unverified until you confirm that code, then verify the address.',
        ),
        const SizedBox(height: 16),
        KpTextField(
          label: 'Email address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 16),
        KpButton(label: 'Send code', busy: _busy, onTap: _busy ? null : _send),
      ],
    );
  }
}

class _EmailVerify extends StatefulWidget {
  const _EmailVerify({required this.repository});

  final ContactsRepository repository;

  @override
  State<_EmailVerify> createState() => _EmailVerifyState();
}

class _EmailVerifyState extends State<_EmailVerify> {
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await widget.repository.requestEmailVerification();
      if (!mounted) return;
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _CodePage(
            title: 'Verify email',
            sentTo: 'your email address',
            confirm: (code) => widget.repository.verifyEmail(challengeId: ticket.challengeId, code: code),
          ),
        ),
      );
      if (done == true && mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = contactErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const KpScreenTitle(
          'Verify email',
          'We will send a code to the address on your account. After this, receipts can go there.',
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 16),
        KpButton(label: 'Send code', busy: _busy, onTap: _busy ? null : _send),
      ],
    );
  }
}

class _CodePage extends StatefulWidget {
  const _CodePage({required this.title, required this.sentTo, required this.confirm});

  final String title;
  final String sentTo;
  final Future<ContactBook> Function(String code) confirm;

  @override
  State<_CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<_CodePage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().length < 4) {
      setState(() => _error = 'Enter the code you received.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.confirm(_code.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = contactErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        KpScreenTitle(widget.title, 'Enter the code sent to ${widget.sentTo}.'),
        const SizedBox(height: 16),
        KpTextField(
          label: 'One-time code',
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          prefixIcon: Icons.password_rounded,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 16),
        KpButton(label: 'Confirm', busy: _busy, onTap: _busy ? null : _verify),
      ],
    );
  }
}

class _Lock {
  const _Lock({required this.remainingDays, required this.supportEmail, required this.supportWhatsApp});

  final int remainingDays;
  final String supportEmail;
  final String supportWhatsApp;

  static _Lock? from(Object error) {
    if (error is! ApiException || error.code != 'PHONE_CHANGE_LOCKED') return null;
    return _Lock(
      remainingDays: (error.details['remainingDays'] as num?)?.toInt() ?? 0,
      supportEmail: error.details['supportEmail']?.toString() ?? 'support@kumpay.cm',
      supportWhatsApp: error.details['supportWhatsApp']?.toString() ?? '+237 690 00 00 00',
    );
  }
}

String _formatPhone(String? e164) {
  if (e164 == null || e164.isEmpty) return 'Not set';
  return Phone.toNationalDisplay(e164).isEmpty ? e164 : '${Phone.countryCode} ${Phone.toNationalDisplay(e164)}';
}

String contactErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'PHONE_CHANGE_LOCKED':
        final days = (error.details['remainingDays'] as num?)?.toInt();
        return days == null
            ? 'You can change this number again later.'
            : 'You can change this number again in $days days.';
      case 'PHONE_TAKEN':
        return 'That number is already used by another account.';
      case 'CONFLICT':
        return 'That email is already used by another account.';
      case 'NOT_FOUND':
        return error.message;
    }
  }
  return authErrorMessage(error);
}
