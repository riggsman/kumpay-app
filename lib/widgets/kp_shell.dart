import 'package:flutter/material.dart';

import '../theme/kp_theme.dart';
import 'kp_brand.dart';

class KpStatusBar extends StatelessWidget {
  const KpStatusBar({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? const Color(0xFFFDF9EE) : KpColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
      child: Row(
        children: [
          Text(
            '9:41',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
          ),
          const Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, size: 16, color: color),
          const SizedBox(width: 5),
          Icon(Icons.wifi_rounded, size: 16, color: color),
          const SizedBox(width: 5),
          Icon(Icons.battery_full_rounded, size: 18, color: color),
        ],
      ),
    );
  }
}

class KpHomeIndicator extends StatelessWidget {
  const KpHomeIndicator({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Container(
          width: 122,
          height: 5,
          decoration: BoxDecoration(
            color:
                (onDark ? Colors.white : KpColors.ink).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

/// A phone-sized preview frame used on desktop and in the gallery.
class KpPhoneFrame extends StatelessWidget {
  const KpPhoneFrame(
      {super.key, required this.child, this.width = 390, this.height = 844});

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < width + 48) return child;

        final scale = (constraints.maxHeight / height).clamp(0.0, 1.0);
        final frame = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(46),
            border: Border.all(color: const Color(0xFFD9D2BF), width: 8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2B142A23),
                blurRadius: 60,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(width, height),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
              ),
              child: child,
            ),
          ),
        );

        if (scale >= 1) return Center(child: frame);

        return Center(
          child: SizedBox(
            width: width * scale,
            height: height * scale,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: OverflowBox(
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: frame,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pops the screen the user is looking at.
///
/// The first screen has nowhere to return to, so this does nothing there.
void kpBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) navigator.pop();
}

/// Drops every screen pushed above the first one.
///
/// Home and sign-in live on that first route, so "Back to home" and
/// "Back to login" land on the screen that is already there.
void kpBackToStart(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class KpAuthHeader extends StatelessWidget {
  const KpAuthHeader({
    super.key,
    this.onBack,
    this.trailing,
    this.light = false,
    this.centeredBrand = true,
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final bool light;
  final bool centeredBrand;

  @override
  Widget build(BuildContext context) {
    final back = _BackButton(onBack: onBack, light: light);

    if (!centeredBrand) {
      return Row(
        children: [
          back,
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      );
    }

    return Row(
      children: [
        back,
        Expanded(
          child: Center(child: KpBrand(light: light, compact: true)),
        ),
        SizedBox(width: 42, child: trailing),
      ],
    );
  }
}

class KpSimpleHeader extends StatelessWidget {
  const KpSimpleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.light = false,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BackButton(onBack: onBack, light: light),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: light ? const Color(0xFFFDF9EE) : KpColors.ink,
                ),
          ),
        ),
        SizedBox(
          width: 42,
          height: 42,
          child: trailing ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The round arrow at the top of a screen.
///
/// It is left out on the first route, where there is no previous screen.
/// [onBack] replaces the default pop when a screen needs a different return.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack, required this.light});

  final VoidCallback? onBack;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) {
      return const SizedBox(width: 42, height: 42);
    }
    return KpIconButton(
      icon: Icons.arrow_back_rounded,
      onTap: onBack ?? () => kpBack(context),
      light: light,
    );
  }
}

class KpIconButton extends StatelessWidget {
  const KpIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.light = false,
    this.background,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool light;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ??
              (light ? Colors.white.withValues(alpha: 0.12) : KpColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: light ? Colors.white.withValues(alpha: 0.18) : KpColors.line,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: light ? const Color(0xFFFDF9EE) : KpColors.ink,
        ),
      ),
    );
  }
}

/// Base page used by every artboard.
class KpPage extends StatelessWidget {
  const KpPage({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.bottomNav,
    this.background,
    this.soft = false,
    this.scroll = true,
    this.padding = const EdgeInsets.fromLTRB(22, 8, 22, 18),
    this.showStatusBar = true,
    this.showHomeIndicator = true,
    this.statusBarOnDark = false,
    this.centerBody = false,
    this.bodySpacing = 0,
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final Widget? bottomNav;
  final Color? background;
  final bool soft;
  final bool scroll;
  final EdgeInsets padding;
  final bool showStatusBar;
  final bool showHomeIndicator;
  final bool statusBarOnDark;
  final bool centerBody;
  final double bodySpacing;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (soft ? KpColors.soft : KpColors.canvas);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: centerBody ? MainAxisSize.min : MainAxisSize.max,
      children: _spaced(children, bodySpacing),
    );

    return ColoredBox(
      color: bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (showStatusBar) KpStatusBar(onDark: statusBarOnDark),
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 2),
                child: header,
              ),
            Expanded(
              child: scroll
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: padding,
                      child: body,
                    )
                  : Padding(
                      padding: padding,
                      child: centerBody ? Center(child: body) : body,
                    ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 2),
                child: footer,
              ),
            if (bottomNav != null) bottomNav!,
            if (showHomeIndicator) KpHomeIndicator(onDark: statusBarOnDark),
          ],
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> children, double spacing) {
    if (spacing <= 0) return children;
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i < children.length - 1) out.add(SizedBox(height: spacing));
    }
    return out;
  }
}

class KpScreenTitle extends StatelessWidget {
  const KpScreenTitle(this.title, [this.subtitle]);

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KpColors.muted,
                  height: 1.55,
                ),
          ),
        ],
      ],
    );
  }
}

class KpStackEnd extends StatelessWidget {
  const KpStackEnd({super.key, required this.children, this.spacing = 8});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}
