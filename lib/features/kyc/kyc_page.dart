import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/kyc/kyc_repository.dart';
import '../../state/auth_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

const _documents = [
  ('id_front', 'ID front'),
  ('id_back', 'ID back'),
  ('selfie', 'Selfie'),
  ('proof_of_address', 'Proof of address'),
];

/// Identity verification for the signed-in account.
class KycPage extends StatefulWidget {
  const KycPage({super.key, required this.repository});

  final KycRepository repository;

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  KycStatus? _status;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await widget.repository.load();
      if (!mounted) return;
      AuthScope.read(context).applyKyc(status.kyc);
      setState(() => _status = status);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await widget.repository.start();
      await _reload();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload(String kind) async {
    final request = _status?.request;
    if (request == null) return;
    final file = await FilePicker.pickFile(type: FileType.image);
    final bytes = file == null ? null : await file.readAsBytes();
    if (bytes == null || bytes.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.repository.upload(
        requestId: request.id,
        kind: kind,
        bytes: bytes,
        filename: file!.name,
        contentType: 'image/jpeg',
      );
      await _reload();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final request = status?.request;
    final open = request != null && (request.status == 'pending' || request.status == 'in_progress');
    return KpPage(
      header: KpSimpleHeader(
        title: 'Identity',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpScreenTitle(
          'Verify your identity',
          'A card can be created only after this request is approved. A rejection includes the reason.',
        ),
        if (_loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
        if (status != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  request == null ? 'Not started' : 'Request ${request.reference ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              KpPill(label: _label(request?.status ?? status.kyc), tone: _tone(request?.status ?? status.kyc)),
            ],
          ),
          if (request?.niu != null) ...[
            const SizedBox(height: 10),
            Text('NIU ${request!.niu}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
          if (request?.rejectionReason != null) ...[
            const SizedBox(height: 10),
            KpTip(tone: KpTipTone.warning, child: Text(request!.rejectionReason!)),
          ],
          if (status.kyc != 'approved' && request?.status != 'approved' && (request == null || request.status == 'rejected')) ...[
            const SizedBox(height: 16),
            KpButton(
              label: request == null ? 'Start verification' : 'Submit again',
              busy: _busy,
              onTap: _busy ? null : _start,
            ),
          ],
          if (open) ...[
            const SizedBox(height: 16),
            const KpSectionHeader(title: 'Documents'),
            for (final document in _documents) ...[
              _DocRow(
                label: document.$2,
                done: request.has(document.$1),
                busy: _busy,
                onTap: () => _upload(document.$1),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.label, required this.done, required this.busy, required this.onTap});

  final String label;
  final bool done;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
          if (done)
            const KpPill(label: 'Uploaded', tone: KpPillTone.green)
          else
            KpTextLink(busy ? 'Please wait' : 'Upload', onTap: busy ? null : onTap),
        ],
      ),
    );
  }
}

String _label(String status) {
  return switch (status) {
    'pending' => 'Waiting',
    'in_progress' => 'In review',
    'approved' => 'Approved',
    'rejected' => 'Rejected',
    _ => 'Not started',
  };
}

KpPillTone _tone(String status) {
  return switch (status) {
    'approved' => KpPillTone.green,
    'rejected' => KpPillTone.red,
    'in_progress' => KpPillTone.gold,
    _ => KpPillTone.neutral,
  };
}

String _message(Object error) {
  if (error is ApiException) return error.message;
  return "Couldn't reach KumPay. Check your connection and try again.";
}
