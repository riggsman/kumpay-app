import 'package:flutter/widgets.dart';

import '../features/feature_flags/app_feature.dart';
import 'feature_flags_controller.dart';

/// Publishes [FeatureFlagsController] and rebuilds when a flag changes.
class FeatureFlagsScope extends InheritedNotifier<FeatureFlagsController> {
  const FeatureFlagsScope({
    super.key,
    required FeatureFlagsController controller,
    required super.child,
  }) : super(notifier: controller);

  static FeatureFlagsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FeatureFlagsScope>()
        ?.notifier;
  }

  /// Whether [feature] is currently offered.
  ///
  /// With no scope above [context], the built-in default is used so design
  /// previews and tests keep their current layout until a controller is mounted.
  static bool enabled(BuildContext context, AppFeature feature) {
    final controller = maybeOf(context);
    if (controller == null) return feature.defaultEnabled;
    return controller.isEnabled(feature);
  }
}
