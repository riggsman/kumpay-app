import 'package:flutter/material.dart';

import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';

/// PIN change flow: current PIN → OTP → new PIN (PIN-1).
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _stage = 0;
  String _current = '';
  bool _error = false;
  final _otp = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _append(String digit) {
    if (_current.length >= 4) return;
    setState(() {
      _current = '$_current$digit';
      _error = false;
    });
  }

  void _backspace() {
    if (_current.isEmpty) return;
    setState(() {
      _current = _current.substring(0, _current.length - 1);
      _error = false;
    });
  }

  void _confirmCurrent() {
    if (_current.length < 4) return;
    setState(() => _stage = 1);
  }

  void _changePin() {
    final pin = _newPin.text;
    final confirm = _confirm.text;
    if (pin.length < 4 || pin != confirm || pin == _current) return;

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
                  child: KpStateIcon(type: KpStateIconType.success, size: 64)),
              const SizedBox(height: 14),
              Text(
                'PIN changed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your new PIN is active. We sent a confirmation message to your primary phone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              KpButton(
                label: 'Done',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      ('Enter your current PIN', 'Confirm it’s you before setting a new PIN.'),
      (
        'Verify your phone',
        'Enter the 6-digit code sent to your primary number.'
      ),
      ('Set a new PIN', 'Choose a 4-digit PIN you haven’t used before.'),
    ];
    final title = titles[_stage];

    final footer = switch (_stage) {
      0 => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KpButton(
              label: 'Continue',
              onTap: _current.length == 4 ? _confirmCurrent : null,
            ),
            KpKeypad(onKey: _append, onBackspace: _backspace),
          ],
        ),
      1 => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KpButton(
              label: 'Verify code',
              onTap: _otp.text.length == 6
                  ? () => setState(() => _stage = 2)
                  : null,
            ),
            KpTextLink(
              'Resend code',
              color: KpColors.muted,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A new code was sent to •••456.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: KpColors.primary,
                ),
              ),
            ),
          ],
        ),
      _ => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KpButton(
              label: 'Change PIN',
              onTap: _newPin.text.length == 4 && _newPin.text == _confirm.text
                  ? _changePin
                  : null,
            ),
            KpTextLink(
              'Cancel',
              color: KpColors.muted,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
    };

    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: KpSimpleHeader(
        title: 'Change PIN',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: footer,
      children: [
        KpStepDots(count: 3, active: _stage),
        const SizedBox(height: 14),
        KpScreenTitle(title.$1, title.$2),
        const SizedBox(height: 20),
        if (_stage == 0) ...[
          _PinDots(count: _current.length),
          if (_error) ...[
            const SizedBox(height: 10),
            const KpInlineError('Incorrect current PIN. 2 attempts left.'),
          ],
          const SizedBox(height: 14),
          const KpTip(
            tone: KpTipTone.info,
            child: Text(
              '3 wrong attempts lock PIN changes for 15 minutes. You’ll be notified after a successful change.',
            ),
          ),
          const SizedBox(height: 6),
          KpTextLink(
            'Forgot your PIN?',
            color: KpColors.muted,
            onTap: () => setState(() => _error = true),
          ),
        ],
        if (_stage == 1) ...[
          KpOtpBoxes(controller: _otp, onCompleted: (_) => setState(() {})),
          const SizedBox(height: 12),
          const KpTip(
            tone: KpTipTone.warning,
            child: Text(
              'A new PIN is only set after this code is verified. Never share it with anyone.',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: KpColors.surface,
                borderRadius: BorderRadius.circular(KpRadius.pill),
                border: Border.all(color: KpColors.line),
              ),
              child: Text(
                'Code expires in 05:00',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 9,
                    ),
              ),
            ),
          ),
        ],
        if (_stage == 2) ...[
          KpTextField(
            label: 'New PIN',
            hint: '••••',
            controller: _newPin,
            obscure: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.lock_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          KpTextField(
            label: 'Confirm new PIN',
            hint: '••••',
            controller: _confirm,
            obscure: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.lock_reset_rounded,
            onChanged: (_) => setState(() {}),
            errorText: _confirm.text.isNotEmpty &&
                    _confirm.text.length == 4 &&
                    _confirm.text != _newPin.text
                ? 'PINs do not match'
                : null,
          ),
          const SizedBox(height: 12),
          const KpTip(
            tone: KpTipTone.success,
            child: Text(
              'Avoid birthdays or repeated digits. Your PIN is hashed and never shown to staff.',
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 13,
              color: KpColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 5),
            Text(
              'Protected by app lock and OTP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: KpColors.muted,
                    fontSize: 8.5,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < count;
        return Container(
          width: 44,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? KpColors.softGreen : KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(
              color: filled ? KpColors.primary : KpColors.line,
              width: filled ? 1.5 : 1,
            ),
          ),
          child: filled
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: KpColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        );
      }),
    );
  }
}
