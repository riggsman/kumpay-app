import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

/// Makes the [AuthController] available to the widget tree and rebuilds
/// dependents when the session changes.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
  }

  static AuthController? maybeRead(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AuthScope>()?.notifier;
  }

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope above this context');
    return scope!.notifier!;
  }

  /// Like [of] but does not subscribe to changes. Use in callbacks.
  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope above this context');
    return scope!.notifier!;
  }
}
