import 'package:flutter/material.dart';

import '../../core/phone.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'auth_messages.dart';
import 'otp_page.dart';

/// Creates an account, then verifies the phone. The API records this device
/// when that code is accepted.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final phone = Phone.normalize(_phone.text);
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter your full name.');
      return;
    }
    if (phone == null) {
      setState(() => _error = 'Enter a valid Cameroon phone number.');
      return;
    }
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address, or leave it blank.');
      return;
    }
    if (!_accepted) {
      setState(() => _error = 'Please accept the Terms of Service and Privacy Policy.');
      return;
    }

    final auth = AuthScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.requestOtp(_phone.text, name: name, email: email.isEmpty ? null : email);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const OtpPage()),
      );
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      soft: true,
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        const KpScreenTitle(
          'Create your account',
          'We’ll verify your phone with a one-time code and save this device on your account.',
        ),
        const SizedBox(height: 18),
        KpTextField(
          label: 'Full name',
          hint: 'Aïcha Ngono',
          controller: _name,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 14),
        KpPhoneField(
          controller: _phone,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 14),
        KpTextField(
          label: 'Email address',
          hint: 'you@example.com',
          controller: _email,
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          optional: 'optional',
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        _Consent(
          checked: _accepted,
          onTap: () => setState(() => _accepted = !_accepted),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 18),
        KpButton(
          label: 'Create account',
          busy: _busy,
          onTap: _busy ? null : _create,
        ),
      ],
    );
  }
}

class _Consent extends StatelessWidget {
  const _Consent({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: checked ? KpColors.primary : KpColors.muted,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'I agree to the Terms of Service and Privacy Policy.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.ink,
                    fontSize: 11,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
