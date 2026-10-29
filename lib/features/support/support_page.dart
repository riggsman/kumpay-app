import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/support/support_repository.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Signed-in support requests. Staff claim and resolve stay on the staff desk.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key, required this.repository});

  final SupportRepository repository;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  List<SupportTicket> _tickets = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tickets = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : "Couldn't load your requests.";
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.length < 3) {
      setState(() => _error = 'Add a subject of at least 3 characters.');
      return;
    }
    if (message.isEmpty) {
      setState(() => _error = 'Tell us what happened.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.create(subject: subject, body: message);
      _subject.clear();
      _message.clear();
      if (!mounted) return;
      setState(() => _sending = false);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error is ApiException ? error.message : "Couldn't send that request.";
      });
    }
  }

  Future<void> _open(SupportTicket ticket) async {
    var shown = ticket;
    try {
      shown = await widget.repository.open(ticket.id);
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KpColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shown.subject,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              KpPill(label: _statusLabel(shown.status), tone: _statusTone(shown.status)),
              if ((shown.body ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  shown.body!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KpColors.ink2,
                        fontSize: 12,
                        height: 1.5,
                      ),
                ),
              ],
              if ((shown.resolution ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                KpTip(tone: KpTipTone.success, child: Text(shown.resolution!)),
              ],
              const SizedBox(height: 14),
              KpButton(label: 'Close', onTap: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpSimpleHeader(
        title: 'Help & support',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpScreenTitle(
          'Send a request',
          'A support agent will reply on your primary phone, and on your email once it is verified.',
        ),
        const SizedBox(height: 16),
        KpTextField(
          label: 'Subject',
          hint: 'Card declined at the shop',
          controller: _subject,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        KpTextField(
          label: 'What happened',
          hint: 'Include the time and what you expected.',
          controller: _message,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 14),
        KpButton(
          label: _sending ? 'Sending…' : 'Send request',
          onTap: _sending ? null : _send,
        ),
        const SizedBox(height: 18),
        const KpTip(
          tone: KpTipTone.warning,
          child: Text('KumPay staff will never ask for your OTP, PIN or password.'),
        ),
        const SizedBox(height: 18),
        const KpSectionHeader(title: 'Your requests'),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (_tickets.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('You have not contacted support yet.'),
          )
        else
          for (final ticket in _tickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TicketTile(ticket: ticket, onTap: () => _open(ticket)),
            ),
      ],
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KpColors.surface,
      borderRadius: BorderRadius.circular(KpRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KpRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KpRadius.md),
            border: Border.all(color: KpColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KpColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ticketTime(ticket.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: KpColors.muted,
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ),
              KpPill(label: _statusLabel(ticket.status), tone: _statusTone(ticket.status)),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'in_progress' => 'In progress',
    'processed' => 'Resolved',
    _ => 'Waiting',
  };
}

KpPillTone _statusTone(String status) {
  return switch (status) {
    'in_progress' => KpPillTone.gold,
    'processed' => KpPillTone.green,
    _ => KpPillTone.neutral,
  };
}

String _ticketTime(String? iso) {
  final parsed = DateTime.tryParse(iso ?? '');
  if (parsed == null) return '';
  final local = parsed.toLocal();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} · $hour:$minute';
}
