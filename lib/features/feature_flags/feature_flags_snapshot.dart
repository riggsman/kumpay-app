import 'package:flutter/foundation.dart';

import '../services/platform_service.dart';
import 'app_feature.dart';
import 'platform_alert.dart';

/// One consistent view of every platform feature flag.
class FeatureFlagsSnapshot {
  const FeatureFlagsSnapshot({
    required this.flags,
    required this.version,
    this.updatedAt,
    this.services = const [],
    this.alert,
  });

  final Map<String, bool> flags;

  /// Monotonic revision. A slower response with a smaller version is ignored.
  final int version;
  final DateTime? updatedAt;

  /// Services the platform has published. Empty until the snapshot includes them.
  final List<PlatformService> services;

  /// Marketing alert. Null until the snapshot includes an `alert` object.
  final PlatformAlert? alert;

  factory FeatureFlagsSnapshot.defaults() {
    return FeatureFlagsSnapshot(
      flags: {
        for (final feature in AppFeature.values)
          feature.key: feature.defaultEnabled,
      },
      version: 0,
    );
  }

  factory FeatureFlagsSnapshot.fromJson(Map<String, dynamic> json) {
    final flags = <String, bool>{
      for (final feature in AppFeature.values)
        feature.key: feature.defaultEnabled,
    };
    final raw = json['flags'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is bool) flags[key.toString()] = value;
      });
    }
    return FeatureFlagsSnapshot(
      flags: flags,
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      services: PlatformService.listFrom(json['services']),
      alert: PlatformAlert.tryParse(json['alert']),
    );
  }

  bool isEnabled(AppFeature feature) =>
      flags[feature.key] ?? feature.defaultEnabled;

  @override
  bool operator ==(Object other) {
    return other is FeatureFlagsSnapshot &&
        other.version == version &&
        mapEquals(other.flags, flags) &&
        _sameServices(other.services, services) &&
        other.alert == alert;
  }

  @override
  int get hashCode => Object.hash(
        version,
        Object.hashAll(
          flags.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
        Object.hashAll(services),
        alert,
      );
}

bool _sameServices(List<PlatformService> left, List<PlatformService> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
