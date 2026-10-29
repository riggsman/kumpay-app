/// A home-screen message the platform turns on for a campaign.
///
/// Absent from the snapshot means the platform has not published one. An
/// object with `enabled: false` hides the alert, including the built-in
/// preview. `enabled: true` shows [title] and [message] to everyone.
class PlatformAlert {
  const PlatformAlert({
    required this.enabled,
    required this.title,
    required this.message,
    this.action = '',
  });

  final bool enabled;
  final String title;
  final String message;

  /// Where a tap goes: `bills`, `wallet`, or `send`. Empty stays on Home.
  final String action;

  static PlatformAlert? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    if (json['enabled'] != true) {
      return const PlatformAlert(enabled: false, title: '', message: '');
    }
    final title = json['title']?.toString().trim() ?? '';
    final message = (json['message'] ?? json['body'])?.toString().trim() ?? '';
    if (title.isEmpty) {
      return const PlatformAlert(enabled: false, title: '', message: '');
    }
    final action = json['action']?.toString().trim().toLowerCase() ?? '';
    return PlatformAlert(
      enabled: true,
      title: title,
      message: message,
      action: switch (action) {
        'bills' || 'wallet' || 'send' => action,
        _ => '',
      },
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlatformAlert &&
        other.enabled == enabled &&
        other.title == title &&
        other.message == message &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(enabled, title, message, action);
}
