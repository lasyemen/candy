class PhoneUtils {
  /// Normalize various KSA formats into 9665XXXXXXXXX
  /// Accepts: 5XXXXXXXX, 05XXXXXXXXX, 9665XXXXXXXXX, +9665XXXXXXXXX, 009665XXXXXXXX
  static String? normalizeKsaPhone(String raw) {
    if (raw.trim().isEmpty) return null;
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    // Strip international prefixes
    if (digits.startsWith('00966')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('966')) {
      digits = digits.substring(3);
    }

    // Strip leading 00 (rare), after removing country code
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // Local 05XXXXXXXXX -> 5XXXXXXXX
    if (digits.length == 10 && digits.startsWith('05')) {
      digits = digits.substring(1);
    }

    // Expect now local 9 digits starting with 5
    if (digits.length == 9 && digits.startsWith('5')) {
      return '966$digits';
    }

    return null; // invalid
  }

  static bool isValidKsaPhone(String raw) => normalizeKsaPhone(raw) != null;
}
