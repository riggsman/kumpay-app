/// Phone number helpers for Cameroon numbers (default country code +237).
///
/// Users type national-format numbers such as `677 12 34 56`. The backend
/// only ever receives E.164 (`+237677123456`).
abstract final class Phone {
  static const countryCode = '+237';
  static const _nationalLength = 9;

  /// Returns the E.164 form of [input], or `null` if it is not a valid
  /// Cameroon mobile/landline number.
  static String? normalize(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00237')) digits = digits.substring(5);
    if (digits.length == _nationalLength + 3 && digits.startsWith('237')) {
      digits = digits.substring(3);
    }
    if (digits.length != _nationalLength) return null;
    if (!digits.startsWith('6') && !digits.startsWith('2')) return null;
    return '$countryCode$digits';
  }

  /// Masks an E.164 number for display, e.g. `••• ••• 456`.
  static String mask(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    final tail =
        digits.length >= 3 ? digits.substring(digits.length - 3) : digits;
    return '••• ••• $tail';
  }

  /// Formats an E.164 number for the national-format field: `677 12 34 56`.
  static String toNationalDisplay(String e164) {
    final national = e164.startsWith(countryCode)
        ? e164.substring(countryCode.length)
        : e164;
    final b = StringBuffer();
    for (var i = 0; i < national.length; i++) {
      if (i == 3 || i == 5 || i == 7) b.write(' ');
      b.write(national[i]);
    }
    return b.toString();
  }
}
