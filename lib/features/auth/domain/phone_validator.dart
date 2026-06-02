class PhoneValidator {
  static String formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final parts = <String>[];
    if (digits.isNotEmpty) parts.add(digits.substring(0, 1));
    if (digits.length > 1) {
      parts.add(digits.substring(1, digits.length > 3 ? 3 : digits.length));
    }
    if (digits.length > 3) {
      parts.add(digits.substring(3, digits.length > 5 ? 5 : digits.length));
    }
    if (digits.length > 5) {
      parts.add(digits.substring(5, digits.length > 7 ? 7 : digits.length));
    }
    if (digits.length > 7) {
      parts.add(digits.substring(7, digits.length > 9 ? 9 : digits.length));
    }
    return parts.join(' ');
  }

  static bool isValidMoroccanPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return false;
    // Moroccan numbers start with 5, 6, 7 or 8 (without the 0)
    final firstDigit = digits.substring(0, 1);
    return ['5', '6', '7', '8'].contains(firstDigit);
  }

  static String toE164(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return '+212$digits';
  }
}
