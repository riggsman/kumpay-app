import 'package:flutter/material.dart';

import '../../preview/preview_page.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_shell.dart';
import '../../widgets/kp_visuals.dart';
import '../auth/help_screens.dart';
import '../home/home_screen.dart';

/// Client onboarding — identity verification introduction.
class KycIntroScreen extends StatelessWidget {
  const KycIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: KpSimpleHeader(
        title: 'Identity verification',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: KpColors.gradientForest,
            borderRadius: BorderRadius.circular(KpRadius.xl),
            boxShadow: KpShadows.balance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: KpColors.gold,
                      size: 23,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: KpColors.gold,
                      borderRadius: BorderRadius.circular(KpRadius.pill),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        color: KpColors.primaryDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Verify your identity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFDF9EE),
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock your virtual card, higher limits and full wallet features.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFFDF9EE).withValues(alpha: 0.72),
                      fontSize: 11,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const KpSectionHeader(title: 'How it works'),
        const SizedBox(height: 4),
        const _StepRow(
          number: '1',
          title: 'Your details',
          body: 'Legal name, date of birth and ID number.',
        ),
        const _StepRow(
          number: '2',
          title: 'Document photos',
          body:
              'Front and back of your national ID or passport, plus a selfie.',
        ),
        const _StepRow(
          number: '3',
          title: 'Quick review',
          body: 'Our compliance team reviews most requests within 24 hours.',
          last: true,
        ),
        const SizedBox(height: 14),
        const KpTip(
          tone: KpTipTone.success,
          child: Text(
            'Your documents are encrypted and stored privately. They’re only used to verify your identity.',
          ),
        ),
        const SizedBox(height: 20),
        KpButton(
          label: 'Start verification',
          icon: Icons.arrow_forward_rounded,
          onTap: () => kpOpen(
            context,
            const KycFormScreen(),
            title: 'KYC · details & documents',
            step: 0,
          ),
        ),
        const SizedBox(height: 4),
        KpTextLink(
          'Do this later',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const HomeScreen(),
            title: 'Home dashboard',
            step: 23,
          ),
        ),
      ],
    );
  }
}

/// KYC details + document upload.
class KycFormScreen extends StatefulWidget {
  const KycFormScreen({super.key});

  @override
  State<KycFormScreen> createState() => _KycFormScreenState();
}

class _KycFormScreenState extends State<KycFormScreen> {
  bool _idFront = false;
  bool _idBack = false;
  bool _selfie = false;
  bool _submitted = false;
  String _docType = 'National ID';

  bool get _ready => _idFront && _idBack && _selfie;

  void _submit() {
    setState(() => _submitted = true);
    if (!_ready) return;

    kpOpen(
      context,
      const KycSubmittedScreen(),
      title: 'KYC submitted',
      step: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: KpSimpleHeader(
        title: 'Verify identity',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpStepDots(count: 3, active: 0),
        const SizedBox(height: 18),
        const KpScreenTitle(
          'Tell us about you',
          'Use the exact details printed on your government ID.',
        ),
        const SizedBox(height: 16),
        const KpTextField(
          label: 'Full legal name',
          hint: 'Aïcha Ngono',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        const KpTextField(
          label: 'Date of birth',
          hint: 'DD / MM / YYYY',
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 14),
        const KpFieldLabel('Document type'),
        Row(
          children: [
            for (final type in ['National ID', 'Passport']) ...[
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _docType = type),
                  borderRadius: BorderRadius.circular(KpRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _docType == type
                          ? KpColors.softGreen
                          : KpColors.surface,
                      borderRadius: BorderRadius.circular(KpRadius.md),
                      border: Border.all(
                        color:
                            _docType == type ? KpColors.primary : KpColors.line,
                        width: _docType == type ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _docType == type
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 16,
                          color: _docType == type
                              ? KpColors.primary
                              : KpColors.muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          type,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KpColors.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (type == 'National ID') const SizedBox(width: 9),
            ],
          ],
        ),
        const SizedBox(height: 14),
        const KpTextField(
          label: 'ID number',
          hint: 'e.g. 1234567890123',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 14),
        const KpTextField(
          label: 'Residential address',
          hint: 'Akwa, Douala',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 22),
        const KpSectionHeader(title: 'Document photos'),
        const SizedBox(height: 2),
        Text(
          'Make sure all corners are visible and text is readable.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KpColors.muted,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 12),
        _UploadTile(
          title: 'ID front',
          subtitle: 'Photo of the front of your national ID',
          icon: Icons.credit_card_rounded,
          uploaded: _idFront,
          onTap: () => setState(() => _idFront = !_idFront),
        ),
        const SizedBox(height: 9),
        _UploadTile(
          title: 'ID back',
          subtitle: 'Photo of the back of your national ID',
          icon: Icons.credit_card_outlined,
          uploaded: _idBack,
          onTap: () => setState(() => _idBack = !_idBack),
        ),
        const SizedBox(height: 9),
        _UploadTile(
          title: 'Selfie',
          subtitle: 'Hold your ID next to your face',
          icon: Icons.face_retouching_natural_rounded,
          uploaded: _selfie,
          onTap: () => setState(() => _selfie = !_selfie),
        ),
        if (_submitted && !_ready) ...[
          const SizedBox(height: 10),
          const KpInlineError(
            'Upload all three photos before submitting for review.',
          ),
        ],
        const SizedBox(height: 16),
        const KpTip(
          tone: KpTipTone.warning,
          child: Text(
            'Documents must be valid and unedited. Blurry or expired documents are rejected.',
          ),
        ),
        const SizedBox(height: 20),
        KpButton(
          label: 'Submit for review',
          onTap: _submit,
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Takes about 3 minutes',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: KpColors.muted,
                  fontSize: 9,
                ),
          ),
        ),
      ],
    );
  }
}

/// KYC pending review.
class KycSubmittedScreen extends StatelessWidget {
  const KycSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: const KpAuthHeader(),
      children: [
        const SizedBox(height: 8),
        const Center(
            child: KpStateIcon(type: KpStateIconType.success, size: 88)),
        const SizedBox(height: 18),
        Text(
          'Submitted for review',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 25),
        ),
        const SizedBox(height: 8),
        Text(
          'Thanks, Aïcha. Our compliance team is reviewing your documents. Most requests are reviewed within 24 hours.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: KpColors.surface,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 18, color: KpColors.warning),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'KYC status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                    ),
                  ),
                  const KpPill(label: 'Pending', tone: KpPillTone.gold),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const _TimelineRow(
                title: 'Documents submitted',
                subtitle: 'Just now',
                done: true,
              ),
              const _TimelineRow(
                title: 'Compliance review',
                subtitle: 'Usually within 24 hours',
                active: true,
              ),
              const _TimelineRow(
                title: 'Decision',
                subtitle: 'You’ll get an SMS and WhatsApp message',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'We’ll notify you on your primary phone ending in ***456. No need to resubmit unless we ask.',
          ),
        ),
        const SizedBox(height: 20),
        KpButton(
          label: 'Back to home',
          onTap: () => kpOpen(
            context,
            const HomeScreen(),
            title: 'Home dashboard',
            step: 23,
          ),
        ),
      ],
    );
  }
}

/// KYC rejected — resubmission entry point.
class KycRejectedScreen extends StatelessWidget {
  const KycRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: KpSimpleHeader(
        title: 'Verification update',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const SizedBox(height: 8),
        const Center(
            child: KpStateIcon(type: KpStateIconType.danger, size: 88)),
        const SizedBox(height: 18),
        Text(
          'We couldn’t verify your ID',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Your submission needs another look. You can fix the issue and resubmit.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: KpColors.dangerSoft,
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.danger.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reason from compliance',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KpColors.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                'The back of your ID is blurry. Please upload a sharp photo with all four corners visible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const KpTip(
          tone: KpTipTone.gold,
          child: Text(
            'Use natural light, avoid glare, and keep the document flat. Photos must be under 5 MB.',
          ),
        ),
        const SizedBox(height: 20),
        KpButton(
          label: 'Resubmit documents',
          onTap: () => kpOpen(
            context,
            const KycFormScreen(),
            title: 'KYC · resubmit',
            step: 0,
          ),
        ),
        const SizedBox(height: 8),
        KpButton(
          label: 'Contact support',
          style: KpButtonStyle.outline,
          onTap: () => kpOpen(
            context,
            const HelpScreen(),
            title: 'Contact support',
            step: 14,
          ),
        ),
      ],
    );
  }
}

/// KYC approved with NIU.
class KycApprovedScreen extends StatelessWidget {
  const KycApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.profile),
      header: const KpAuthHeader(),
      children: [
        const SizedBox(height: 8),
        const Center(
            child: KpStateIcon(type: KpStateIconType.success, size: 88)),
        const SizedBox(height: 18),
        Text(
          'You’re verified!',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 8),
        Text(
          'Your identity is confirmed. Your virtual card and higher limits are now available.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KpColors.muted,
                fontSize: 11.5,
                height: 1.55,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: KpColors.gradientForest,
            borderRadius: BorderRadius.circular(KpRadius.lg),
            boxShadow: KpShadows.balance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR NIU',
                style: TextStyle(
                  color: const Color(0xFFFDF9EE).withValues(alpha: 0.6),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'CM-2026-004821',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: KpColors.gold,
                      fontSize: 22,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unique, permanent taxpayer identifier',
                style: TextStyle(
                  color: const Color(0xFFFDF9EE).withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const KpDetailCard(
          rows: [
            KpDetailRow('Verification status', 'Approved'),
            KpDetailRow('Reviewed by', 'KumPay Compliance'),
            KpDetailRow('Date', '24 May 2026'),
          ],
        ),
        const SizedBox(height: 16),
        const KpTip(
          tone: KpTipTone.success,
          child: Text(
            'Your NIU is immutable. Keep it safe — you’ll need it for tax and business payments.',
          ),
        ),
        const SizedBox(height: 20),
        KpButton(
          label: 'Create my virtual card',
          icon: Icons.credit_card_rounded,
          onTap: () => kpOpen(
            context,
            const HomeScreen(),
            title: 'Home dashboard',
            step: 23,
          ),
        ),
        KpTextLink(
          'Back to home',
          color: KpColors.muted,
          onTap: () => kpOpen(
            context,
            const HomeScreen(),
            title: 'Home dashboard',
            step: 23,
          ),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.uploaded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: uploaded ? KpColors.successSoft : KpColors.surface,
          borderRadius: BorderRadius.circular(KpRadius.md),
          border: Border.all(
            color: uploaded ? KpColors.success : KpColors.line,
            width: uploaded ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: uploaded ? Colors.white : KpColors.soft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                uploaded ? Icons.check_rounded : icon,
                size: 19,
                color: uploaded ? KpColors.success : KpColors.ink2,
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    uploaded ? 'Uploaded · tap to replace' : subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: uploaded ? KpColors.success : KpColors.muted,
                          fontSize: 9.5,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: uploaded ? Colors.white : KpColors.goldSoft,
                borderRadius: BorderRadius.circular(KpRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    uploaded
                        ? Icons.refresh_rounded
                        : Icons.add_a_photo_outlined,
                    size: 12,
                    color: uploaded ? KpColors.success : KpColors.goldDeep,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    uploaded ? 'Replace' : 'Upload',
                    style: TextStyle(
                      color: uploaded ? KpColors.success : KpColors.goldDeep,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.body,
    this.last = false,
  });

  final String number;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: KpColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: KpColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: KpColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
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
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.muted,
                          fontSize: 10,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    this.done = false,
    this.active = false,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: done
                    ? KpColors.success
                    : active
                        ? KpColors.goldSoft
                        : KpColors.soft,
                shape: BoxShape.circle,
                border:
                    active ? Border.all(color: KpColors.gold, width: 2) : null,
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
            if (!last)
              Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 3),
                color: KpColors.line,
              ),
          ],
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KpColors.muted,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
