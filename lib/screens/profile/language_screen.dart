import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';

/// App language picker.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

final languageChoice = ValueNotifier<String>('en');

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected = languageChoice.value;

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: KpSimpleHeader(
        title: 'Language',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: 'Apply language',
        onTap: () {
          languageChoice.value = _selected;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selected == 'fr'
                    ? 'Langue définie sur Français.'
                    : 'Language set to ${demoLanguages.firstWhere((l) => l.code == _selected).name}.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: KpColors.primary,
            ),
          );
        },
      ),
      children: [
        const KpScreenTitle(
          'Choose your language',
          'Menu labels, receipts and support messages will use this language.',
        ),
        const SizedBox(height: 16),
        for (final language in demoLanguages) ...[
          InkWell(
            onTap: () => setState(() => _selected = language.code),
            borderRadius: BorderRadius.circular(KpRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                color: _selected == language.code
                    ? KpColors.softGreen
                    : KpColors.surface,
                borderRadius: BorderRadius.circular(KpRadius.md),
                border: Border.all(
                  color: _selected == language.code
                      ? KpColors.primary
                      : KpColors.line,
                  width: _selected == language.code ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: KpColors.surface,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      language.code.toUpperCase(),
                      style: const TextStyle(
                        color: KpColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KpColors.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          language.native,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KpColors.muted,
                                    fontSize: 9,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (language.code == 'en')
                    const KpPill(label: 'Default', tone: KpPillTone.gold),
                  const SizedBox(width: 6),
                  Icon(
                    _selected == language.code
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 19,
                    color: _selected == language.code
                        ? KpColors.primary
                        : KpColors.muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'Some legal documents and bank messages may only be available in French or English.',
          ),
        ),
      ],
    );
  }
}
