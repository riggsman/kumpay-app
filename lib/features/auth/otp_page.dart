import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/phone.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';
import 'auth_messages.dart';

/// Enter the six-digit code sent to the phone number entered on the login page.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const _length = 6;

  final _otp = TextEditingController();
  Timer? _ticker;
  bool _verifying = false;
  bool _resending = false;
  bool _locked = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    // Re-render once a second so the resend countdown stays current.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otp.dispose();
    super.dispose();
  }

  bool get _complete => _otp.text.length == _length;

  Future<void> _verify() async {
    if (!_complete || _verifying || _locked) return;
    final auth = AuthScope.read(context);
    setState(() {
      _verifying = true;
      _error = null;
      _notice = null;
    });
    try {
      await auth.verifyOtp(_otp.text);
      if (!mounted) return;
      // Signed in: the root gate now shows the home screen underneath.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = authErrorMessage(e);
        if (e.code == AuthErrorCodes.tooManyAttempts) _locked = true;
        if (e.code == AuthErrorCodes.codeExpired) _locked = true;
      });
      if (e.code == AuthErrorCodes.invalidCode) _otp.clear();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    final auth = AuthScope.read(context);
    final phone = auth.pendingPhone;
    if (phone == null || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
      _notice = null;
    });
    try {
      await auth.requestOtp(phone);
      if (!mounted) return;
      _otp.clear();
      setState(() {
        _locked = false;
        _notice = 'A new code was sent.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final phone = auth.pendingPhone;
    final wait = auth.resendWait;
    final canResend = wait == Duration.zero && !_resending;

    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KpButton(
            label: 'Verify OTP',
            busy: _verifying,
            onTap: _complete && !_locked && !_verifying ? _verify : null,
          ),
          const SizedBox(height: 4),
          KpTextLink(
            canResend ? 'Resend OTP' : 'Resend code in ${_countdown(wait)}',
            color: canResend ? KpColors.primary : KpColors.muted,
            onTap: canResend && !_locked ? _resend : null,
          ),
        ],
      ),
      children: [
        KpScreenTitle(
          'Verify OTP',
          phone == null
              ? 'Request a code to continue.'
              : 'Enter the 6-digit code sent to ${Phone.mask(phone)}.',
        ),
        const SizedBox(height: 20),
        KpOtpBoxes(
          controller: _otp,
          autofocus: !_locked,
          error: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 12),
          Text(
            _notice!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.success,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        const SizedBox(height: 18),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Never share this code with anyone. KumPay staff will never ask for your OTP.',
          ),
        ),
      ],
    );
  }

  static String _countdown(Duration d) {
    final s = d.inSeconds.clamp(0, 3600);
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
