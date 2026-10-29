import 'dart:async';

import 'package:flutter/widgets.dart';

import '../features/feature_flags/app_feature.dart';
import '../features/feature_flags/feature_flags_repository.dart';
import '../features/feature_flags/feature_flags_snapshot.dart';

/// How often the app re-reads flags when the live stream is down.
const Duration kFeatureFlagPollInterval = Duration(seconds: 4);

/// Holds the platform feature snapshot and publishes changes to the tree.
///
/// The first paint uses built-in defaults. After that, a server-sent event
/// applies immediately, and a poll covers a missing or dropped stream. An
/// older [FeatureFlagsSnapshot.version] never overwrites a newer one.
class FeatureFlagsController extends ChangeNotifier
    with WidgetsBindingObserver {
  FeatureFlagsController({
    required FeatureFlagsRepository repository,
    this.pollInterval = kFeatureFlagPollInterval,
  }) : _repository = repository;

  final FeatureFlagsRepository _repository;
  final Duration pollInterval;

  FeatureFlagsSnapshot _snapshot = FeatureFlagsSnapshot.defaults();
  Timer? _poll;
  StreamSubscription<FeatureFlagsSnapshot>? _subscription;
  var _started = false;
  var _disposed = false;
  var _refreshing = false;
  var _observing = false;
  var _streamTicket = 0;
  var _streamSupported = true;

  FeatureFlagsSnapshot get snapshot => _snapshot;

  bool isEnabled(AppFeature feature) => _snapshot.isEnabled(feature);

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
    _listen();
    _poll = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    await refresh();
  }

  /// Pulls the latest snapshot. Failures keep the last good one.
  Future<void> refresh() async {
    if (_disposed || _refreshing) return;
    _refreshing = true;
    try {
      applySnapshot(await _repository.fetch());
    } catch (_) {
      // Stay on the last snapshot. The next poll or stream event retries.
    } finally {
      _refreshing = false;
    }
  }

  void applySnapshot(FeatureFlagsSnapshot next) {
    if (_disposed) return;
    if (_snapshot.version > 0 &&
        (next.version <= 0 || next.version < _snapshot.version)) {
      return;
    }
    final changed = !mapEqualsFlags(_snapshot, next);
    _snapshot = next;
    if (changed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  void _listen() {
    if (!_streamSupported || _disposed) return;
    final ticket = ++_streamTicket;
    _subscription?.cancel();
    _subscription = _repository.watch().listen(
      applySnapshot,
      onError: (Object error, StackTrace _) {
        if (ticket != _streamTicket || _disposed) return;
        if (error is FeatureStreamUnsupported) {
          _streamSupported = false;
          _subscription = null;
          return;
        }
        _relisten(ticket);
      },
      onDone: () {
        if (ticket != _streamTicket || _disposed || !_streamSupported) return;
        _relisten(ticket);
      },
      cancelOnError: true,
    );
  }

  void _relisten(int ticket) {
    _subscription = null;
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (_disposed || ticket != _streamTicket) return;
      _listen();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _streamTicket++;
    _poll?.cancel();
    _subscription?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

bool mapEqualsFlags(FeatureFlagsSnapshot left, FeatureFlagsSnapshot right) {
  if (left.flags.length != right.flags.length) return false;
  for (final entry in left.flags.entries) {
    if (right.flags[entry.key] != entry.value) return false;
  }
  return true;
}
