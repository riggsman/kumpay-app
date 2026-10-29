import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/money/money_repository.dart';
import '../../features/money/live_money.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_app_nav.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// Renames linked devices and removes a session the person no longer uses.
class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key, this.repository});

  final MoneyRepository? repository;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  static const _preview = [
    AccountDevice(
      id: 'preview-this',
      label: 'This phone',
      model: 'iPhone 15 Pro',
      platform: 'iOS',
      lastSeenAt: null,
      current: true,
    ),
    AccountDevice(
      id: 'preview-other',
      label: '',
      model: 'Android',
      platform: 'Android',
      lastSeenAt: null,
    ),
  ];

  List<AccountDevice> _devices = const [];
  var _loading = true;
  var _busy = false;
  String? _error;

  MoneyRepository? get _repo => widget.repository ?? moneyRepo(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.repository ?? moneyRepo(context);
    if (repo == null) {
      setState(() {
        _devices = _preview;
        _loading = false;
      });
      return;
    }
    try {
      final devices = await repo.devices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            error is ApiException ? error.message : "Couldn't load devices.";
      });
    }
  }

  Future<void> _rename(AccountDevice device) async {
    final repo = _repo;
    final label = await showDialog<String>(
      context: context,
      builder: (dialog) => _RenameDeviceDialog(initial: device.displayName),
    );
    if (label == null || !mounted) return;
    if (label.isEmpty) {
      setState(() => _error = 'Enter a name for this device.');
      return;
    }
    if (repo == null) {
      setState(() => _error = 'Sign in to rename a device.');
      return;
    }
    if (device.id.isEmpty) {
      setState(() => _error = 'This device cannot be renamed yet.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.renameDevice(id: device.id, label: label);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't rename that device.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(AccountDevice device) async {
    final repo = _repo;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Remove device'),
        content: Text(
          'Sign ${device.displayName} out of this wallet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (repo == null) {
      setState(() => _error = 'Sign in to remove a device.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.removeDevice(device.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't remove that device.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOutOthers() async {
    final repo = _repo;
    if (repo == null) {
      setState(() => _error = 'Sign in to manage devices.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.signOutOthers();
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : "Couldn't sign out the other devices.";
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      bottomNav: kpAppNav(context, active: KpTab.wallet),
      header: KpSimpleHeader(
        title: 'Linked devices',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      footer: KpButton(
        label: 'Sign out other devices',
        style: KpButtonStyle.outline,
        onTap: _busy ? null : _signOutOthers,
      ),
      children: [
        const KpTip(
          tone: KpTipTone.info,
          child: Text(
            'You can rename any device. Removing one signs that session out. This device stays signed in.',
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_devices.isEmpty)
          const KpDetailCard(
            rows: [KpDetailRow('Devices', 'None captured yet')],
          )
        else
          for (final device in _devices) ...[
            _DeviceRow(
              device: device,
              busy: _busy,
              onRename: () => _rename(device),
              onRemove: device.current ? null : () => _remove(device),
            ),
            const SizedBox(height: 8),
          ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
      ],
    );
  }
}

class _RenameDeviceDialog extends StatefulWidget {
  const _RenameDeviceDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<_RenameDeviceDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Device name'),
      content: KpTextField(label: 'Name', controller: _controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.busy,
    required this.onRename,
    required this.onRemove,
  });

  final AccountDevice device;
  final bool busy;
  final VoidCallback onRename;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (device.platform.isNotEmpty) device.platform,
      if (device.current) 'This device',
      if (!device.current && device.model != device.displayName) device.model,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: KpColors.surface,
        borderRadius: BorderRadius.circular(KpRadius.md),
        border: Border.all(color: KpColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.devices_outlined, color: KpColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KpColors.muted,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('rename-device-${device.id}'),
            tooltip: 'Rename',
            onPressed: busy ? null : onRename,
            icon: const Icon(Icons.edit_outlined, color: KpColors.ink2),
          ),
          if (onRemove != null)
            IconButton(
              key: Key('remove-device-${device.id}'),
              tooltip: 'Remove',
              onPressed: busy ? null : onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: KpColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}
