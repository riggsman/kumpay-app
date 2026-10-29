import 'package:flutter/material.dart';

import '../theme/kp_theme.dart';
import '../widgets/kp_shell.dart';

class KpPreviewPage extends StatelessWidget {
  const KpPreviewPage({
    super.key,
    required this.title,
    required this.screen,
    this.step,
    this.note,
  });

  final String title;
  final Widget screen;
  final int? step;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE7D7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
              child: Row(
                children: [
                  KpIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (step != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KpColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(KpRadius.pill),
                                ),
                                child: Text(
                                  step!.toString().padLeft(2, '0'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFFFDF9EE),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 8.5,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (note != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: KpColors.muted,
                                      fontSize: 9.5,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: KpColors.surface,
                      borderRadius: BorderRadius.circular(KpRadius.pill),
                      border: Border.all(color: KpColors.line),
                    ),
                    child: Text(
                      '390 × 844',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: KpColors.muted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: KpPhoneFrame(
                  child: Material(
                    color: KpColors.canvas,
                    child: screen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Route<T> kpPreviewRoute<T>({
  required String title,
  required Widget screen,
  int? step,
  String? note,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => KpPreviewPage(
      title: title,
      screen: screen,
      step: step,
      note: note,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0.02),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

/// True only for design review builds (`--dart-define=KP_GALLERY=true`).
/// Release and debug app builds leave this false, so no preview chrome
/// (screen numbers, titles, 390×844 badge, phone frame) is shown.
const bool kDesignPreview = bool.fromEnvironment('KP_GALLERY');

/// Opens [screen]. In design review builds it is wrapped in the numbered
/// preview frame; in app builds it is a plain full-screen route.
Future<T?> kpOpen<T>(
  BuildContext context,
  Widget screen, {
  required String title,
  int? step,
  String? note,
}) {
  final route = kDesignPreview
      ? kpPreviewRoute<T>(title: title, screen: screen, step: step, note: note)
      : MaterialPageRoute<T>(builder: (_) => screen);
  return Navigator.of(context).push<T>(route);
}
