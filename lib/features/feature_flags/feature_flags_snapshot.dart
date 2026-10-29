import 'package:flutter/foundation.dart';

import 'app_feature.dart';

/// One consistent view of every platform feature flag.
class FeatureFlagsSnapshot {
  const FeatureFlagsSnapshot({
    required this.flags,
    required this.version,
    this.updatedAt,
  });

  final Map<String, bool> flags;

  /// Monotonic revision. A slower response with a smaller version is ignored.
  final int version;
  final DateTime? updatedAt;

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
    );
  }

  bool isEnabled(AppFeature feature) =>
      flags[feature.key] ?? feature.defaultEnabled;

  @override
  bool operator ==(Object other) {
    return other is FeatureFlagsSnapshot &&
        other.version == version &&
        mapEquals(other.flags, flags);
  }

  @override
  int get hashCode => Object.hash(
    version,
    Object.hashAll(
      flags.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
