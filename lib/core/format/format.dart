import 'package:intl/intl.dart';

abstract class TantinFormat {
  static final _numberFormat = NumberFormat('#,##0', 'fr_MA');

  /// Formats an amount to Dirhams.
  /// Example: 1500 -> "1 500 DH"
  static String fmtDH(num amount) {
    // NumberFormat with fr_MA uses narrow non-breaking space (U+202F) by default
    // We replace it to standard space as requested
    final formatted = _numberFormat
        .format(amount)
        .replaceAll('\u202F', ' ')
        .replaceAll('\u00A0', ' ');
    return '$formatted DH';
  }

  /// Formats a number with spaces for thousands
  static String fmtNum(num amount) {
    return _numberFormat
        .format(amount)
        .replaceAll('\u202F', ' ')
        .replaceAll('\u00A0', ' ');
  }
}
