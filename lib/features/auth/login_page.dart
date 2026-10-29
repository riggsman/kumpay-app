import 'package:flutter/material.dart';

import '../../core/phone.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import 'auth_messages.dart';
import 'otp_page.dart';
import 'register_page.dart';

/// Phone sign-in: asks for the registration number and sends a one-time code.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  String? get _e164 => Phone.normalize(_phone.text);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final auth = AuthScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.requestOtp(_phone.text);
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
    final valid = _e164 != null;

    return KpPage(
      soft: true,
      header: const KpAuthHeader(centeredBrand: true),
      children: [
        const KpScreenTitle(
          'Welcome back',
          'Sign in with your phone number. We will send a one-time code to verify it is you.',
        ),
        const SizedBox(height: 6),
        const Center(child: KpDeviceIllustration(size: 142)),
        const SizedBox(height: 4),
        KpPhoneField(
          controller: _phone,
          label: 'Phone number',
          hint: '677 12 34 56',
          autofocus: true,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 14),
        KpButton(
          label: 'Send OTP',
          icon: Icons.arrow_forward_rounded,
          busy: _busy,
          onTap: valid && !_busy ? _sendCode : null,
        ),
        const SizedBox(height: 10),
        Text(
          'A 6-digit code will be sent to your registered phone number.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KpColors.muted,
                fontSize: 9.5,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New to KumPay? ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 11,
                  ),
            ),
            KpTextLink(
              'Create account',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SecurityBadge(),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 15, color: KpColors.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Your security is our priority',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: KpColors.ink2,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
