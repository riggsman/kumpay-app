import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/pin/pin_repository.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Current PIN, then a code to the primary phone, then a different new PIN.
class PinPage extends StatefulWidget {
  const PinPage({super.key, required this.repository});

  final PinRepository repository;

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final _current = TextEditingController();
  final _code = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  int _stage = 0;
  String? _challengeId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _code.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _current.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'Enter your 4-digit PIN.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await widget.repository.verifyCurrent(pin);
      if (!mounted) return;
      setState(() {
        _challengeId = challenge.challengeId;
        _stage = 1;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change() async {
    final next = _next.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(next)) {
      setState(() => _error = 'Choose a PIN of 4 to 6 digits.');
      return;
    }
    if (next != _confirm.text.trim()) {
      setState(() => _error = 'The two PINs do not match.');
      return;
    }
    if (next == _current.text.trim()) {
      setState(() => _error = 'The new PIN must be different.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.change(
        challengeId: _challengeId ?? '',
        code: _code.text.trim(),
        newPin: next,
        confirmPin: _confirm.text.trim(),
      );
      if (!mounted) return;
      setState(() => _stage = 2);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_stage) {
      0 => ('Enter your current PIN', 'If you have not set a PIN yet, this one is checked and a code is sent to your phone.'),
      1 => ('Enter the code', 'We sent a code to your primary phone. Then choose a different PIN.'),
      _ => ('PIN changed', 'Your new PIN is active. A confirmation was sent to your primary phone.'),
    };
    return KpPage(
      header: KpAuthHeader(onBack: () => Navigator.of(context).maybePop()),
      children: [
        KpScreenTitle(title.$1, title.$2),
        const SizedBox(height: 16),
        if (_stage == 0)
          KpTextField(
            label: 'Current PIN',
            controller: _current,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscure: true,
          ),
        if (_stage == 1) ...[
          KpTextField(label: 'One-time code', controller: _code, keyboardType: TextInputType.number, maxLength: 6),
          const SizedBox(height: 12),
          KpTextField(
            label: 'New PIN',
            controller: _next,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscure: true,
          ),
          const SizedBox(height: 12),
          KpTextField(
            label: 'Confirm new PIN',
            controller: _confirm,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscure: true,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 16),
        if (_stage == 0) KpButton(label: 'Continue', busy: _busy, onTap: _busy ? null : _verify),
        if (_stage == 1) KpButton(label: 'Change PIN', busy: _busy, onTap: _busy ? null : _change),
        if (_stage == 2)
          KpButton(label: 'Done', onTap: () => Navigator.of(context).maybePop()),
      ],
    );
  }
}

String _message(Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'INVALID_PIN' => 'That PIN is not correct.',
      'PIN_LOCKED' => 'Too many attempts. PIN changes are locked for 15 minutes.',
      'PIN_UNCHANGED' => 'The new PIN must be different from the current one.',
      _ => error.message,
    };
  }
  return "Couldn't reach KumPay. Check your connection and try again.";
}
