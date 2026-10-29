import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/kp_theme.dart';

enum KpButtonStyle { primary, gold, outline, success, danger, soft }

class KpButton extends StatelessWidget {
  const KpButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = KpButtonStyle.primary,
    this.icon,
    this.trailing,
    this.height = 54,
    this.expand = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final KpButtonStyle style;
  final IconData? icon;
  final Widget? trailing;
  final double height;
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      KpButtonStyle.primary => (
          KpColors.primary,
          const Color(0xFFFDF9EE),
          null
        ),
      KpButtonStyle.gold => (KpColors.gold, KpColors.primaryDark, null),
      KpButtonStyle.outline => (KpColors.surface, KpColors.ink, KpColors.line),
      KpButtonStyle.success => (KpColors.success, Colors.white, null),
      KpButtonStyle.danger => (KpColors.danger, Colors.white, null),
      KpButtonStyle.soft => (KpColors.goldSoft, KpColors.primaryDark, null),
    };

    final disabled = onTap == null || busy;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 19, color: fg),
        if (busy || icon != null) const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(KpRadius.lg),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(KpRadius.lg),
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KpRadius.lg),
              border: border == null ? null : Border.all(color: border),
              boxShadow: style == KpButtonStyle.primary
                  ? [
                      BoxShadow(
                        color: KpColors.primary.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class KpTextLink extends StatelessWidget {
  const KpTextLink(
    this.label, {
    super.key,
    this.onTap,
    this.color = KpColors.primary,
    this.align = TextAlign.center,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final TextAlign align;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: align == TextAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: align,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KpFieldLabel extends StatelessWidget {
  const KpFieldLabel(this.label, {super.key, this.optional});

  final String label;
  final String? optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: KpColors.ink2,
                ),
          ),
          if (optional != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: KpColors.soft,
                borderRadius: BorderRadius.circular(KpRadius.pill),
              ),
              child: Text(
                optional!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: KpColors.muted,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class KpTextField extends StatelessWidget {
  const KpTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.obscure = false,
    this.maxLength,
    this.optional,
    this.errorText,
    this.suffix,
    this.onChanged,
    this.textInputAction,
    this.autofocus = false,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool obscure;
  final int? maxLength;
  final String? optional;
  final String? errorText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpFieldLabel(label, optional: optional),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLength: maxLength,
          maxLines: maxLines,
          autofocus: autofocus,
          textInputAction: textInputAction,
          onChanged: onChanged,
          inputFormatters: maxLength == null
              ? null
              : [LengthLimitingTextInputFormatter(maxLength)],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: KpColors.ink,
                fontWeight: FontWeight.w600,
              ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: KpColors.muted),
            suffixIcon: suffix,
            errorText: errorText,
            errorStyle: const TextStyle(color: KpColors.danger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class KpPhoneField extends StatelessWidget {
  const KpPhoneField({
    super.key,
    this.controller,
    this.label = 'Phone number',
    this.hint = '677 12 34 56',
    this.country = '+237',
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String label;
  final String hint;
  final String country;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpFieldLabel(label),
        Row(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: KpColors.surface,
                borderRadius: BorderRadius.circular(KpRadius.md),
                border: Border.all(color: KpColors.line),
              ),
              child: Row(
                children: [
                  const Text('🇨🇲', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 7),
                  Text(
                    country,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                autofocus: autofocus,
                onChanged: onChanged,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    size: 19,
                    color: KpColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class KpOtpBoxes extends StatefulWidget {
  const KpOtpBoxes({
    super.key,
    this.controller,
    this.length = 6,
    this.autofocus = true,
    this.error = false,
    this.showSystemKeyboard = true,
    this.onCompleted,
  });

  final TextEditingController? controller;
  final int length;
  final bool autofocus;
  final bool error;
  final bool showSystemKeyboard;
  final ValueChanged<String>? onCompleted;

  @override
  State<KpOtpBoxes> createState() => _KpOtpBoxesState();
}

class _KpOtpBoxesState extends State<KpOtpBoxes> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_controller.text.length == widget.length) {
      widget.onCompleted?.call(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final active = _focus.hasFocus ? text.length : -1;

    return GestureDetector(
      onTap: () {
        if (widget.showSystemKeyboard) _focus.requestFocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final filled = index < text.length;
              final focused = index == active;
              final color = widget.error
                  ? KpColors.danger
                  : focused
                      ? KpColors.primary
                      : filled
                          ? KpColors.primaryLight
                          : KpColors.line;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 49,
                height: 57,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.error
                      ? KpColors.dangerSoft
                      : filled
                          ? KpColors.softGreen
                          : KpColors.surface,
                  borderRadius: BorderRadius.circular(KpRadius.md),
                  border: Border.all(color: color, width: focused ? 1.8 : 1),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: KpColors.primary.withValues(alpha: 0.12),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filled ? text[index] : '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: widget.error ? KpColors.danger : KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                ),
              );
            }),
          ),
          if (widget.showSystemKeyboard)
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  showCursor: false,
                  maxLength: widget.length,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class KpKeypad extends StatelessWidget {
  const KpKeypad({super.key, required this.onKey, required this.onBackspace});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String value, {bool action = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: action ? KpColors.soft : KpColors.surface,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => onKey(value),
              child: SizedBox(
                height: 45,
                child: Center(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget backspace() {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: KpColors.soft,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: onBackspace,
              child: const SizedBox(
                height: 45,
                child: Icon(Icons.backspace_outlined, size: 19),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [key('1'), key('2'), key('3')]),
          Row(children: [key('4'), key('5'), key('6')]),
          Row(children: [key('7'), key('8'), key('9')]),
          Row(children: [const Spacer(flex: 1), key('0'), backspace()]),
        ],
      ),
    );
  }
}

class KpTip extends StatelessWidget {
  const KpTip({
    super.key,
    required this.child,
    this.tone = KpTipTone.info,
    this.icon,
  });

  final Widget child;
  final KpTipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, iconData) = switch (tone) {
      KpTipTone.info => (
          KpColors.infoSoft,
          KpColors.info,
          Icons.shield_outlined
        ),
      KpTipTone.success => (
          KpColors.successSoft,
          KpColors.success,
          Icons.verified_user_outlined
        ),
      KpTipTone.warning => (
          KpColors.warningSoft,
          KpColors.warning,
          Icons.warning_amber_rounded
        ),
      KpTipTone.danger => (
          KpColors.dangerSoft,
          KpColors.danger,
          Icons.gpp_bad_outlined
        ),
      KpTipTone.gold => (
          KpColors.goldSoft,
          KpColors.goldDeep,
          Icons.lightbulb_outline_rounded
        ),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KpRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? iconData, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg,
                    height: 1.5,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

enum KpTipTone { info, success, warning, danger, gold }

enum KpStateIconType { success, warning, danger, info, lock }

class KpStateIcon extends StatelessWidget {
  const KpStateIcon({super.key, required this.type, this.size = 84});

  final KpStateIconType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (type) {
      KpStateIconType.success => (
          KpColors.successSoft,
          KpColors.success,
          Icons.check_rounded
        ),
      KpStateIconType.warning => (
          KpColors.warningSoft,
          KpColors.warning,
          Icons.schedule_rounded
        ),
      KpStateIconType.danger => (
          KpColors.dangerSoft,
          KpColors.danger,
          Icons.close_rounded
        ),
      KpStateIconType.info => (
          KpColors.infoSoft,
          KpColors.info,
          Icons.mail_outline_rounded
        ),
      KpStateIconType.lock => (
          KpColors.soft,
          KpColors.primary,
          Icons.lock_outline_rounded
        ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, size: size * 0.42, color: fg),
    );
  }
}

class KpEmptySpace extends StatelessWidget {
  const KpEmptySpace({super.key, this.height = 16});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class KpPill extends StatelessWidget {
  const KpPill({
    super.key,
    required this.label,
    this.tone = KpPillTone.green,
    this.icon,
  });

  final String label;
  final KpPillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      KpPillTone.green => (KpColors.successSoft, KpColors.success),
      KpPillTone.gold => (KpColors.goldSoft, KpColors.goldDeep),
      KpPillTone.red => (KpColors.dangerSoft, KpColors.danger),
      KpPillTone.neutral => (KpColors.soft, KpColors.muted),
      KpPillTone.dark => (KpColors.primary, const Color(0xFFFDF9EE)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KpRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ),
    );
  }
}

enum KpPillTone { green, gold, red, neutral, dark }

class KpDetailRow {
  const KpDetailRow(this.label, this.value,
      {this.total = false, this.valueColor});

  final String label;
  final String value;
  final bool total;
  final Color? valueColor;
}

class KpDetailCard extends StatelessWidget {
  const KpDetailCard({super.key, required this.rows, this.padding});

  final List<KpDetailRow> rows;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.lg),
        border: Border.all(color: KpColors.line),
        boxShadow: KpShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                color: rows[i].total
                    ? KpColors.line
                    : KpColors.line.withValues(alpha: 0.7),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                rows[i].total ? KpColors.ink : KpColors.muted,
                            fontWeight: rows[i].total
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 11.5,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: rows[i].valueColor ??
                                (rows[i].total
                                    ? KpColors.primary
                                    : KpColors.ink),
                            fontWeight: rows[i].total
                                ? FontWeight.w900
                                : FontWeight.w700,
                            fontSize: rows[i].total ? 12.5 : 11.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class KpSectionHeader extends StatelessWidget {
  const KpSectionHeader(
      {super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
        ),
        const Spacer(),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Text(
              action!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: KpColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
            ),
          ),
      ],
    );
  }
}

class KpServiceTile extends StatelessWidget {
  const KpServiceTile({
    super.key,
    required this.label,
    required this.icon,
    this.tone = KpServiceTone.green,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final KpServiceTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      KpServiceTone.green => (KpColors.softGreen, KpColors.primary),
      KpServiceTone.gold => (KpColors.goldSoft, KpColors.goldDeep),
      KpServiceTone.rose => (KpColors.dangerSoft, KpColors.danger),
      KpServiceTone.info => (KpColors.infoSoft, KpColors.info),
      KpServiceTone.neutral => (KpColors.soft, KpColors.ink2),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 21, color: fg),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: KpColors.ink2,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

enum KpServiceTone { green, gold, rose, info, neutral }

class KpActivityTile extends StatelessWidget {
  const KpActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.incoming,
    required this.icon,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String currency;
  final bool incoming;
  final IconData icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = incoming ? KpColors.success : KpColors.ink;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: incoming ? KpColors.successSoft : KpColors.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: incoming ? KpColors.success : KpColors.ink2,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.muted,
                            fontSize: 9.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                  ),
                  Text(
                    currency,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 8.5,
                          letterSpacing: 0.4,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: KpColors.line.withValues(alpha: 0.65)),
      ],
    );
  }
}

class KpToggleRow extends StatelessWidget {
  const KpToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KpColors.soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: KpColors.ink2),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KpColors.muted,
                        fontSize: 9.5,
                      ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: KpColors.primary,
              activeTrackColor: KpColors.softGreen,
              inactiveThumbColor: KpColors.muted,
              inactiveTrackColor: KpColors.soft,
            ),
          ),
        ],
      ),
    );
  }
}

class KpSettingsTile extends StatelessWidget {
  const KpSettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.trailingText,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: danger ? KpColors.dangerSoft : KpColors.soft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 17,
                color: danger ? KpColors.danger : KpColors.ink2,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: danger ? KpColors.danger : KpColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 9.5,
                    ),
              ),
              const SizedBox(width: 4),
            ],
            if (!danger)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: KpColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

class KpInlineError extends StatelessWidget {
  const KpInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline_rounded,
              size: 15, color: KpColors.danger),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KpColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class KpBulletList extends StatelessWidget {
  const KpBulletList(
      {super.key, required this.items, this.color = KpColors.ink2});

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: const BoxDecoration(
                    color: KpColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontSize: 10.5,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
