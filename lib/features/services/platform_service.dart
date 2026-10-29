/// The only field keys a platform service may ask the person to fill in.
enum ServiceFieldKey {
  amount('amount', 'Amount'),
  receiver('receiver', 'Receiver'),
  type('type', 'Type');

  const ServiceFieldKey(this.wire, this.defaultLabel);

  final String wire;
  final String defaultLabel;

  static ServiceFieldKey? parse(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'amount' => ServiceFieldKey.amount,
      'receiver' => ServiceFieldKey.receiver,
      'type' => ServiceFieldKey.type,
      _ => null,
    };
  }
}

/// One labeled input on a platform-defined service. At most three are shown.
class ServiceField {
  const ServiceField({
    required this.key,
    required this.label,
    this.options = const [],
  });

  final ServiceFieldKey key;
  final String label;
  final List<String> options;

  static ServiceField? tryParse(Object? raw) {
    if (raw is String) {
      final key = ServiceFieldKey.parse(raw);
      if (key == null) return null;
      return ServiceField(key: key, label: key.defaultLabel);
    }
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    final key = ServiceFieldKey.parse(
      json['key']?.toString() ?? json['name']?.toString(),
    );
    if (key == null) return null;
    final label = json['label']?.toString().trim();
    final options = <String>[];
    final rawOptions = json['options'];
    if (rawOptions is List) {
      for (final option in rawOptions) {
        final text = option?.toString().trim() ?? '';
        if (text.isNotEmpty && !options.contains(text)) options.add(text);
      }
    }
    return ServiceField(
      key: key,
      label: label == null || label.isEmpty ? key.defaultLabel : label,
      options: options,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! ServiceField) return false;
    if (other.key != key || other.label != label) return false;
    if (other.options.length != options.length) return false;
    for (var i = 0; i < options.length; i++) {
      if (other.options[i] != options[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(key, label, Object.hashAll(options));
}

/// Result of a service payment. The phone never calls the provider itself.
class ServicePayment {
  const ServicePayment({
    required this.status,
    required this.message,
    required this.providerRequested,
    this.reference = '',
  });

  /// `debited` when the wallet covered it, `provider_pending` when it did not.
  final String status;
  final String message;
  final bool providerRequested;
  final String reference;

  factory ServicePayment.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    final provider =
        json['providerRequested'] == true || status == 'provider_pending';
    final message = json['message']?.toString().trim() ?? '';
    return ServicePayment(
      status: status,
      providerRequested: provider,
      reference: json['reference']?.toString() ?? '',
      message: message.isEmpty
          ? (provider
              ? 'Your balance did not cover this, so the provider request was started.'
              : 'Paid from your KumPay balance.')
          : message,
    );
  }
}

/// A service the platform created. The app renders [name], [logo], and [fields].
///
/// A service with no recognized field is dropped. More than three fields are
/// cut to the first three. `enabled: false` drops it until the platform turns
/// it back on.
class PlatformService {
  const PlatformService({
    required this.id,
    required this.name,
    required this.fields,
    this.logo,
    this.fixedAmount,
    this.currency = 'XAF',
  });

  final String id;
  final String name;
  final String? logo;
  final List<ServiceField> fields;
  final double? fixedAmount;
  final String currency;

  bool get asksForAmount =>
      fields.any((field) => field.key == ServiceFieldKey.amount);

  /// Amount the person entered, or the platform's fixed amount.
  double? resolveAmount(String? entered) {
    if (asksForAmount) {
      final parsed = double.tryParse(
        (entered ?? '').replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      return parsed;
    }
    return fixedAmount;
  }

  /// Absolute logo URL. A bare file name is served from `/media/services/`.
  String? logoUrl(String apiBase) {
    final value = logo?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final root = apiBase.endsWith('/')
        ? apiBase.substring(0, apiBase.length - 1)
        : apiBase;
    if (value.startsWith('/')) return '$root$value';
    return '$root/media/services/${Uri.encodeComponent(value)}';
  }

  static List<PlatformService> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final services = <PlatformService>[];
    for (final entry in raw) {
      final service = tryParse(entry);
      if (service != null && !services.any((item) => item.id == service.id)) {
        services.add(service);
      }
    }
    return services;
  }

  static PlatformService? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((key, value) => MapEntry(key.toString(), value));
    if (json['enabled'] == false) return null;
    final name = (json['name'] ?? json['serviceName'])?.toString().trim() ?? '';
    final id = (json['id'] ?? json['serviceName'] ?? name).toString().trim();
    if (id.isEmpty || name.isEmpty) return null;
    final fields = <ServiceField>[];
    final rawFields = json['fields'];
    if (rawFields is List) {
      for (final entry in rawFields) {
        if (fields.length >= 3) break;
        final field = ServiceField.tryParse(entry);
        if (field == null || fields.any((item) => item.key == field.key)) {
          continue;
        }
        fields.add(field);
      }
    }
    if (fields.isEmpty) return null;
    final fixed = json['fixedAmount'];
    final fixedAmount = fixed is num
        ? fixed.toDouble()
        : double.tryParse(fixed?.toString() ?? '');
    final currency = json['currency']?.toString().trim().toUpperCase();
    return PlatformService(
      id: id,
      name: name,
      logo: json['logo']?.toString(),
      fields: fields,
      fixedAmount: fixedAmount,
      currency: currency == null || currency.isEmpty ? 'XAF' : currency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! PlatformService) return false;
    if (other.id != id ||
        other.name != name ||
        other.logo != logo ||
        other.fixedAmount != fixedAmount ||
        other.currency != currency) {
      return false;
    }
    if (other.fields.length != fields.length) return false;
    for (var i = 0; i < fields.length; i++) {
      if (other.fields[i] != fields[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        logo,
        fixedAmount,
        currency,
        Object.hashAll(fields),
      );
}
